//go:build integration

package budget_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/budget"
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
			budget.realizations,
			budget.batch_items,
			budget.template_items,
			catalog.classes,
			catalog.course_batches,
			catalog.courses,
			identity.departments,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func newService(t *testing.T, pool *pgxpool.Pool) *budget.Service {
	t.Helper()
	repo := budget.NewRepository(pool)
	return budget.NewService(repo, zap.NewNop())
}

func seedCourseAndTemplates(t *testing.T, pool *pgxpool.Pool) (courseID uuid.UUID, actorID uuid.UUID) {
	t.Helper()
	ctx := context.Background()

	actorID = uuid.New()
	_, err := pool.Exec(ctx,
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1, $2, 'x', 'vernonedu_admin')`,
		actorID, actorID.String()+"@test.local")
	require.NoError(t, err)

	deptID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO identity.departments (id, name, leader_id, created_by) VALUES ($1, 'Test Dept', $2, $2)`,
		deptID, actorID)
	require.NoError(t, err)

	courseID = uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO catalog.courses (id, name, department_id, course_creator_id, base_price, min_price, created_by)
		 VALUES ($1, 'Test Course', $2, $3, 0, 0, $3)`,
		courseID, deptID, actorID)
	require.NoError(t, err)

	for i, label := range []string{"Item A", "Item B"} {
		_, err = pool.Exec(ctx,
			`INSERT INTO budget.template_items (id, course_id, label, preset_amount, overridable)
			 VALUES ($1, $2, $3, $4, true)`,
			uuid.New(), courseID, label, float64((i+1)*100))
		require.NoError(t, err)
	}
	return courseID, actorID
}

func seedBatch(t *testing.T, pool *pgxpool.Pool, courseID, actorID uuid.UUID) uuid.UUID {
	t.Helper()
	batchID := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO catalog.course_batches (id, course_id, label, start_date, end_date, price, status, created_by)
		 VALUES ($1, $2, 'Batch 1', now(), now() + interval '30 days', 0, 'draft', $3)`,
		batchID, courseID, actorID)
	require.NoError(t, err)
	return batchID
}

func TestOnBatchCreated_SetsCreatedByToActor(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	courseID, actorID := seedCourseAndTemplates(t, pool)
	batchID := seedBatch(t, pool, courseID, actorID)

	svc := newService(t, pool)
	err := svc.OnBatchCreated(context.Background(), batchID, courseID, actorID)
	require.NoError(t, err)

	repo := budget.NewRepository(pool)
	items, err := repo.ListBatchItems(context.Background(), batchID)
	require.NoError(t, err)
	require.Len(t, items, 2)

	for _, item := range items {
		require.Equal(t, actorID, item.CreatedBy,
			"CreatedBy must equal the actor who created the batch, got zero UUID")
	}
}

func TestUpdateBatchItem_OverridableLock(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	courseID, actorID := seedCourseAndTemplates(t, pool)
	batchID := seedBatch(t, pool, courseID, actorID)

	itemID := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO budget.batch_items (id, course_batch_id, label, planned_amount, overridable, created_by)
		 VALUES ($1, $2, 'Fixed Cost', 500, false, $3)`,
		itemID, batchID, actorID)
	require.NoError(t, err)

	svc := newService(t, pool)

	err = svc.UpdateBatchItem(context.Background(), &budget.BatchBudgetItem{
		ID:            itemID,
		CourseBatchID: batchID,
		Label:         "Fixed Cost",
		PlannedAmount: 999,
		Overridable:   false,
		CreatedBy:     actorID,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "planned_amount is locked for this item")

	err = svc.UpdateBatchItem(context.Background(), &budget.BatchBudgetItem{
		ID:            itemID,
		CourseBatchID: batchID,
		Label:         "Fixed Cost Renamed",
		PlannedAmount: 500,
		Overridable:   false,
		CreatedBy:     actorID,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	})
	require.NoError(t, err)
}
