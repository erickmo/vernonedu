//go:build integration

package franchise_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/franchise"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

const defaultTestDBURL = "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable"

func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DB_URL")
	if url == "" {
		url = defaultTestDBURL
	}
	pool, err := pgxpool.New(context.Background(), url)
	require.NoError(t, err)
	require.NoError(t, pool.Ping(context.Background()))
	return pool
}

func resetSchemas(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			franchise.royalty_payment_records,
			franchise.branch_other_revenues,
			franchise.franchise_agreements,
			franchise.franchisees,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func seedAdminUser(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var adminID uuid.UUID
	err := pool.QueryRow(context.Background(), `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('admin@franchise.test', 'x', 'course_creator')
		RETURNING id`).Scan(&adminID)
	require.NoError(t, err)
	return adminID
}

func newService(t *testing.T, pool *pgxpool.Pool) *franchise.Service {
	t.Helper()
	log := zap.NewNop()
	return franchise.NewService(franchise.NewRepository(pool), events.NewBus(log), log)
}

func TestFranchiseLifecycle(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	adminID := seedAdminUser(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	// 1. Create franchisee
	f := &franchise.Franchisee{
		Name:       "Budi Investor",
		BranchName: "Vernon Bandung",
		Location:   "Bandung, West Java",
		Contact:    "08123456789",
		CreatedBy:  adminID,
	}
	created, err := svc.CreateFranchisee(ctx, f)
	require.NoError(t, err)
	require.Equal(t, franchise.FranchiseeActive, created.Status)
	require.NotEqual(t, uuid.Nil, created.ID)

	// 2. Retrieve franchisee
	got, err := svc.GetFranchiseeByID(ctx, created.ID)
	require.NoError(t, err)
	require.Equal(t, "Vernon Bandung", got.BranchName)

	// 3. List franchisees
	list, err := svc.ListFranchisees(ctx)
	require.NoError(t, err)
	require.Len(t, list, 1)

	// 4. Create agreement
	a := &franchise.FranchiseAgreement{
		FranchiseeID:      created.ID,
		BuyInFee:          decimal.NewFromInt(50000000),
		MonthlyRoyalty:    decimal.NewFromInt(5000000),
		RevenueRoyaltyPct: decimal.NewFromInt(10),
		StartDate:         time.Now(),
	}
	agreement, err := svc.CreateAgreement(ctx, a)
	require.NoError(t, err)
	require.Equal(t, franchise.AgreementActive, agreement.Status)

	// 5. Reject invalid royalty pct
	bad := &franchise.FranchiseAgreement{
		FranchiseeID:      created.ID,
		BuyInFee:          decimal.NewFromInt(1),
		MonthlyRoyalty:    decimal.NewFromInt(1),
		RevenueRoyaltyPct: decimal.NewFromInt(150),
		StartDate:         time.Now(),
	}
	_, err = svc.CreateAgreement(ctx, bad)
	require.Error(t, err)

	// 6. Add branch other revenue
	rev := &franchise.BranchOtherRevenue{
		FranchiseeID: created.ID,
		Label:        "Space rental",
		Amount:       decimal.NewFromInt(2000000),
		RevenueDate:  time.Now(),
		AddedBy:      adminID,
	}
	otherRev, err := svc.AddBranchOtherRevenue(ctx, rev)
	require.NoError(t, err)
	require.NotEqual(t, uuid.Nil, otherRev.ID)

	// 7. Create royalty record
	period := time.Now().Format("2006-01")
	rec, err := svc.CreateRoyaltyRecord(ctx, created.ID, period, adminID)
	require.NoError(t, err)
	require.Equal(t, franchise.RoyaltyUnpaid, rec.Status)
	// Other revenue = 2,000,000; enrollment = 0; revenue royalty = 200,000; total = 5,200,000
	require.True(t, rec.GrossRevenue.Equal(decimal.NewFromInt(2000000)))
	require.True(t, rec.TotalRoyalty.Equal(decimal.NewFromInt(5200000)))

	// 8. Get royalty record
	fetched, err := svc.GetRoyaltyRecord(ctx, created.ID, period)
	require.NoError(t, err)
	require.Equal(t, rec.ID, fetched.ID)

	// 9. Mark royalty paid
	require.NoError(t, svc.MarkRoyaltyPaid(ctx, rec.ID))

	// 10. Verify mark-paid is idempotent (second call returns not-found since status=paid)
	err = svc.MarkRoyaltyPaid(ctx, rec.ID)
	require.Error(t, err)
}

func TestMarkOverdueRoyalties(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	adminID := seedAdminUser(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	// Create franchisee + agreement
	f := &franchise.Franchisee{
		Name: "Test Overdue", BranchName: "Branch X",
		Location: "Jakarta", Contact: "08", CreatedBy: adminID,
	}
	created, err := svc.CreateFranchisee(ctx, f)
	require.NoError(t, err)

	a := &franchise.FranchiseAgreement{
		FranchiseeID:      created.ID,
		BuyInFee:          decimal.NewFromInt(1000000),
		MonthlyRoyalty:    decimal.NewFromInt(1000000),
		RevenueRoyaltyPct: decimal.NewFromInt(5),
		StartDate:         time.Now().AddDate(-1, 0, 0),
	}
	agreement, err := svc.CreateAgreement(ctx, a)
	require.NoError(t, err)
	_ = agreement

	// Insert an old unpaid record directly with a past period
	pastPeriod := time.Now().AddDate(0, -2, 0).Format("2006-01")
	_, err = svc.CreateRoyaltyRecord(ctx, created.ID, pastPeriod, adminID)
	require.NoError(t, err)

	// MarkOverdueRoyalties should mark it overdue
	require.NoError(t, svc.MarkOverdueRoyalties(ctx))

	rec, err := svc.GetRoyaltyRecord(ctx, created.ID, pastPeriod)
	require.NoError(t, err)
	require.Equal(t, franchise.RoyaltyOverdue, rec.Status)
}
