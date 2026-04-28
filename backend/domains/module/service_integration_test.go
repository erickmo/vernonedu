//go:build integration

package module_test

import (
	"context"
	"os"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/module"
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
			catalog.class_module_coverages,
			catalog.batch_module_configs,
			catalog.module_assets,
			catalog.module_versions,
			catalog.modules,
			catalog.classes,
			catalog.course_batches,
			catalog.courses,
			enrollment.enrollments,
			identity.departments,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func newService(t *testing.T, pool *pgxpool.Pool) *module.Service {
	t.Helper()
	repo := module.NewRepository(pool)
	return module.NewService(repo, zap.NewNop())
}

type seedResult struct {
	actorID  uuid.UUID
	courseID uuid.UUID
	batchID  uuid.UUID
	classID  uuid.UUID
}

func seedCatalog(t *testing.T, pool *pgxpool.Pool) seedResult {
	t.Helper()
	ctx := context.Background()

	actorID := uuid.New()
	_, err := pool.Exec(ctx,
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1, $2, 'x', 'vernonedu_admin')`,
		actorID, actorID.String()+"@test.local")
	require.NoError(t, err)

	deptID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO identity.departments (id, name, leader_id, created_by) VALUES ($1, 'Dept', $2, $2)`,
		deptID, actorID)
	require.NoError(t, err)

	courseID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO catalog.courses (id, name, department_id, course_creator_id, base_price, min_price, created_by)
		 VALUES ($1, 'Course', $2, $3, 0, 0, $3)`,
		courseID, deptID, actorID)
	require.NoError(t, err)

	batchID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO catalog.course_batches (id, course_id, label, start_date, end_date, price, status, created_by)
		 VALUES ($1, $2, 'Batch 1', now(), now()+interval '30 days', 0, 'open', $3)`,
		batchID, courseID, actorID)
	require.NoError(t, err)

	classID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO catalog.classes (id, course_batch_id, session_date, start_time, end_time, mode, instructor_id, instructor_type, assigned_by, created_at, updated_at)
		 VALUES ($1, $2, now(), '09:00', '11:00', 'online', $3, 'facilitator', 'dept_leader', now(), now())`,
		classID, batchID, actorID)
	require.NoError(t, err)

	return seedResult{actorID: actorID, courseID: courseID, batchID: batchID, classID: classID}
}

func TestCreateModule(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)

	m, err := svc.CreateModule(context.Background(), seed.courseID, "Intro", 1, seed.actorID)
	require.NoError(t, err)
	require.Equal(t, "Intro", m.Title)
	require.True(t, m.IsActive)
	require.Equal(t, 1, m.Order)
}

func TestPublishVersion_ArchivesPrevious(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)

	m, err := svc.CreateModule(context.Background(), seed.courseID, "Module A", 1, seed.actorID)
	require.NoError(t, err)

	v1, err := svc.CreateModuleVersion(context.Background(), m.ID, "Version 1", nil, seed.actorID)
	require.NoError(t, err)
	err = svc.PublishVersion(context.Background(), m.ID, v1.ID, seed.actorID)
	require.NoError(t, err)

	v2, err := svc.CreateModuleVersion(context.Background(), m.ID, "Version 2", nil, seed.actorID)
	require.NoError(t, err)
	err = svc.PublishVersion(context.Background(), m.ID, v2.ID, seed.actorID)
	require.NoError(t, err)

	v1Fetched, err := svc.GetModuleVersion(context.Background(), v1.ID)
	require.NoError(t, err)
	require.Equal(t, module.ModuleArchived, v1Fetched.Status)

	v2Fetched, err := svc.GetModuleVersion(context.Background(), v2.ID)
	require.NoError(t, err)
	require.Equal(t, module.ModulePublished, v2Fetched.Status)
}

func TestCoverage_AutoFlip(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)

	m, _ := svc.CreateModule(context.Background(), seed.courseID, "Module A", 1, seed.actorID)
	cov, err := svc.CreateCoverage(context.Background(), seed.classID, m.ID, nil, seed.actorID)
	require.NoError(t, err)
	require.Equal(t, module.CoveragePlanned, cov.Status)

	err = svc.AutoFlipPlannedToCovered(context.Background(), seed.classID)
	require.NoError(t, err)

	updated, err := svc.GetCoverage(context.Background(), cov.ID)
	require.NoError(t, err)
	require.Equal(t, module.CoverageCovered, updated.Status)
	require.True(t, updated.IsAutoCovered)
	require.NotNil(t, updated.CoveredAt)
}

func TestBatchProgress(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	seed := seedCatalog(t, pool)
	svc := newService(t, pool)

	m1, _ := svc.CreateModule(context.Background(), seed.courseID, "Mod 1", 1, seed.actorID)
	m2, _ := svc.CreateModule(context.Background(), seed.courseID, "Mod 2", 2, seed.actorID)

	svc.CreateCoverage(context.Background(), seed.classID, m1.ID, nil, seed.actorID)
	svc.CreateCoverage(context.Background(), seed.classID, m2.ID, nil, seed.actorID)
	svc.AutoFlipPlannedToCovered(context.Background(), seed.classID)

	progress, err := svc.GetBatchProgress(context.Background(), seed.batchID)
	require.NoError(t, err)
	require.Equal(t, 2, progress.TotalModules)
	require.Equal(t, 2, progress.CoveredModules)
	require.InDelta(t, 100.0, progress.ProgressPct, 0.01)
}
