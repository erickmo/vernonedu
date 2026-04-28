//go:build integration

package partnerships_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/partnerships"
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
			partnerships.partner_documents,
			partnerships.royalty_payment_records,
			partnerships.franchise_agreements,
			partnerships.franchisees,
			partnerships.partnership_agreements,
			partnerships.branch_other_revenues,
			partnerships.partners,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

// seedActiveAgreement creates a partner + draft agreement, then activates it.
// Returns (partnerID, agreementID).
func seedActiveAgreement(t *testing.T, pool *pgxpool.Pool) (uuid.UUID, uuid.UUID) {
	t.Helper()
	ctx := context.Background()
	createdBy := uuid.New()

	// Seed the user who created the agreement
	_, err := pool.Exec(ctx,
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1,$2,'hash','vernonedu_admin')`,
		createdBy, createdBy.String()+"@test.com",
	)
	require.NoError(t, err)

	// Insert a partner directly
	partnerID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO partnerships.partners (id, name, type, status) VALUES ($1, $2, $3, $4)`,
		partnerID, "Test Partner Corp", "university", "lead",
	)
	require.NoError(t, err)

	// Insert a draft agreement
	agreementID := uuid.New()
	startDate := time.Now()
	_, err = pool.Exec(ctx,
		`INSERT INTO partnerships.partnership_agreements (id, partner_id, title, status, start_date, created_by)
		 VALUES ($1, $2, $3, 'draft', $4, $5)`,
		agreementID, partnerID, "Test Agreement", startDate, createdBy,
	)
	require.NoError(t, err)

	// Activate the agreement
	_, err = pool.Exec(ctx,
		`UPDATE partnerships.partnership_agreements SET status='active' WHERE id=$1`,
		agreementID,
	)
	require.NoError(t, err)

	return partnerID, agreementID
}

func TestTerminateAgreement_PersistsReason(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	_, agreementID := seedActiveAgreement(t, pool)

	repo := partnerships.NewRepository(pool)
	bus := events.NewBus(zap.NewNop())
	svc := partnerships.NewService(repo, bus, zap.NewNop())

	const reason = "contract expired early"
	require.NoError(t, svc.TerminateAgreement(context.Background(), agreementID, reason))

	a, err := repo.GetAgreementByID(context.Background(), agreementID)
	require.NoError(t, err)
	require.NotNil(t, a.TerminationReason, "termination_reason should be persisted")
	require.Equal(t, reason, *a.TerminationReason)
	require.NotNil(t, a.TerminatedAt, "terminated_at should be persisted")
}
