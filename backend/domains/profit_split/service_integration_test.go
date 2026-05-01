//go:build integration

package profit_split_test

import (
	"context"
	"os"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/profit_split"
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
			profit_split.period_bonuses,
			profit_split.batch_split_records,
			profit_split.batch_cost_line_items,
			profit_split.extra_revenues,
			profit_split.course_overrides,
			profit_split.global_settings,
			catalog.course_batches,
			catalog.courses,
			identity.departments,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

type fixture struct {
	ceoID     uuid.UUID
	financeID uuid.UUID
	courseID  uuid.UUID
	batchID   uuid.UUID
}

func seedFixture(t *testing.T, pool *pgxpool.Pool) fixture {
	t.Helper()
	ctx := context.Background()
	var f fixture

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('ceo@t.local','x','ceo') RETURNING id`).Scan(&f.ceoID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('finance@t.local','x','finance') RETURNING id`).Scan(&f.financeID))

	var creatorID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('creator@t.local','x','course_creator') RETURNING id`).Scan(&creatorID))

	var deptID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO identity.departments (name, leader_id, created_by)
		VALUES ('TestDept', $1, $1) RETURNING id`, creatorID).Scan(&deptID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.courses (name, department_id, course_creator_id, base_price, min_price, created_by)
		VALUES ('TestCourse', $1, $2, 1000000, 800000, $2)
		RETURNING id`, deptID, creatorID).Scan(&f.courseID))

	require.NoError(t, pool.QueryRow(ctx, `
		INSERT INTO catalog.course_batches (course_id, label, start_date, end_date, price, created_by)
		VALUES ($1, 'B1', CURRENT_DATE, CURRENT_DATE + 30, 1200000, $2)
		RETURNING id`, f.courseID, creatorID).Scan(&f.batchID))

	return f
}

func newService(t *testing.T, pool *pgxpool.Pool) *profit_split.Service {
	t.Helper()
	log := zap.NewNop()
	return profit_split.NewService(profit_split.NewRepository(pool), events.NewBus(log), log)
}

// TestUpsertGlobalSettings verifies CEO can upsert global split settings.
func TestUpsertGlobalSettings(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	settingsID := uuid.New()
	gs, err := svc.UpdateGlobalSettings(ctx, profit_split.UpdateGlobalSettingsInput{
		ID:               settingsID,
		VernonEduPct:     decimal.NewFromInt(50),
		CourseCreatorPct: decimal.NewFromInt(30),
		DeptLeaderPct:    decimal.NewFromInt(20),
		UpdatedBy:        f.ceoID,
		UpdatedByRole:    "ceo",
	})
	require.NoError(t, err)
	require.NotNil(t, gs)
	require.True(t, gs.VernonEduPct.Equal(decimal.NewFromInt(50)))

	// Upsert again with different values.
	gs2, err := svc.UpdateGlobalSettings(ctx, profit_split.UpdateGlobalSettingsInput{
		ID:               settingsID,
		VernonEduPct:     decimal.NewFromInt(60),
		CourseCreatorPct: decimal.NewFromInt(25),
		DeptLeaderPct:    decimal.NewFromInt(15),
		UpdatedBy:        f.ceoID,
		UpdatedByRole:    "ceo",
	})
	require.NoError(t, err)
	require.True(t, gs2.VernonEduPct.Equal(decimal.NewFromInt(60)))
}

// TestGlobalSettingsForbiddenForNonCEO verifies non-CEO cannot update settings.
func TestGlobalSettingsForbiddenForNonCEO(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	_, err := svc.UpdateGlobalSettings(ctx, profit_split.UpdateGlobalSettingsInput{
		ID:               uuid.New(),
		VernonEduPct:     decimal.NewFromInt(50),
		CourseCreatorPct: decimal.NewFromInt(30),
		DeptLeaderPct:    decimal.NewFromInt(20),
		UpdatedBy:        f.financeID,
		UpdatedByRole:    "finance",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "permission")
}

// TestGlobalSettingsPctValidation verifies percentages must sum to 100.
func TestGlobalSettingsPctValidation(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	_, err := svc.UpdateGlobalSettings(ctx, profit_split.UpdateGlobalSettingsInput{
		ID:               uuid.New(),
		VernonEduPct:     decimal.NewFromInt(50),
		CourseCreatorPct: decimal.NewFromInt(30),
		DeptLeaderPct:    decimal.NewFromInt(10), // sums to 90
		UpdatedBy:        f.ceoID,
		UpdatedByRole:    "ceo",
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "100")
}

// TestCreateCourseOverride verifies CEO can create a course-level override.
func TestCreateCourseOverride(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	co, err := svc.CreateCourseOverride(ctx, profit_split.CreateCourseOverrideInput{
		CourseID:         f.courseID,
		VernonEduPct:     decimal.NewFromInt(40),
		CourseCreatorPct: decimal.NewFromInt(40),
		DeptLeaderPct:    decimal.NewFromInt(20),
		OverriddenBy:     f.ceoID,
		OverriddenByRole: "ceo",
	})
	require.NoError(t, err)
	require.Equal(t, f.courseID, co.CourseID)

	fetched, err := svc.GetCourseOverride(ctx, f.courseID)
	require.NoError(t, err)
	require.True(t, fetched.VernonEduPct.Equal(decimal.NewFromInt(40)))
}

// TestAddAndApproveExtraRevenue verifies finance adds revenue and CEO approves it.
func TestAddAndApproveExtraRevenue(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	er, err := svc.AddExtraRevenue(ctx, profit_split.AddExtraRevenueInput{
		CourseBatchID: f.batchID,
		Label:         "Sponsorship",
		Amount:        decimal.NewFromInt(500000),
		AddedBy:       f.financeID,
		AddedByRole:   "finance",
	})
	require.NoError(t, err)
	require.Equal(t, profit_split.ApprovalPending, er.ApprovalStatus)

	require.NoError(t, svc.ApproveExtraRevenue(ctx, er.ID, f.ceoID, "ceo"))

	fetched, err := svc.GetExtraRevenue(ctx, er.ID)
	require.NoError(t, err)
	require.Equal(t, profit_split.ApprovalApproved, fetched.ApprovalStatus)
	require.NotNil(t, fetched.ApprovedBy)
	require.Equal(t, f.ceoID, *fetched.ApprovedBy)
}

// TestCalculateBatchSplit verifies the split calculation with global settings.
func TestCalculateBatchSplit(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	f := seedFixture(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	// Seed global settings.
	_, err := svc.UpdateGlobalSettings(ctx, profit_split.UpdateGlobalSettingsInput{
		ID:               uuid.New(),
		VernonEduPct:     decimal.NewFromInt(50),
		CourseCreatorPct: decimal.NewFromInt(30),
		DeptLeaderPct:    decimal.NewFromInt(20),
		UpdatedBy:        f.ceoID,
		UpdatedByRole:    "ceo",
	})
	require.NoError(t, err)

	// Seed an approved extra revenue of 200000.
	er, err := svc.AddExtraRevenue(ctx, profit_split.AddExtraRevenueInput{
		CourseBatchID: f.batchID,
		Label:         "Extra",
		Amount:        decimal.NewFromInt(200000),
		AddedBy:       f.financeID,
		AddedByRole:   "finance",
	})
	require.NoError(t, err)
	require.NoError(t, svc.ApproveExtraRevenue(ctx, er.ID, f.ceoID, "ceo"))

	// Seed a fixed cost of 100000.
	_, err = svc.CreateBatchCostLineItem(ctx, profit_split.CreateBatchCostInput{
		CourseBatchID: f.batchID,
		Label:         "Venue",
		Amount:        decimal.NewFromInt(100000),
		CostType:      profit_split.CostFixed,
		ReferenceType: profit_split.RefManual,
		CreatedBy:     f.ceoID,
	})
	require.NoError(t, err)

	// gross = 1000000, extra = 200000 → grossWithExtra = 1200000, cost = 100000, net = 1100000
	gross := decimal.NewFromInt(1000000)
	rec, err := svc.CalculateBatchSplit(ctx, profit_split.CalculateBatchSplitInput{
		BatchID:      f.batchID,
		CourseID:     f.courseID,
		GrossRevenue: gross,
		CalculatedBy: &f.ceoID,
	})
	require.NoError(t, err)
	require.NotNil(t, rec)

	expectedNet := decimal.NewFromInt(1100000)
	require.True(t, rec.NetProfit.Equal(expectedNet), "net=%s", rec.NetProfit)

	expectedVernonEdu := expectedNet.Mul(decimal.NewFromInt(50)).Div(decimal.NewFromInt(100))
	require.True(t, rec.VernonEduAmount.Equal(expectedVernonEdu), "vernonedu=%s", rec.VernonEduAmount)

	// Fetch from repo.
	fetched, err := svc.GetBatchSplitRecord(ctx, f.batchID)
	require.NoError(t, err)
	require.True(t, fetched.NetProfit.Equal(expectedNet))
}

