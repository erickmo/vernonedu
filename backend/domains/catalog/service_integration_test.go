//go:build integration

package catalog_test

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

	"github.com/vernonedu/vernonedu2/backend/domains/catalog"
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
			catalog.batch_module_configs,
			catalog.module_assets,
			catalog.module_versions,
			catalog.modules,
			catalog.classes,
			catalog.course_batches,
			catalog.course_cost_templates,
			catalog.course_format_configs,
			catalog.courses,
			identity.facilitator_proposals,
			identity.facilitator_profiles,
			identity.team_members,
			identity.departments,
			identity.fee_tiers,
			identity.student_profiles,
			identity.students,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

type seed struct {
	creatorID uuid.UUID
	deptID    uuid.UUID
}

func seedIdentity(t *testing.T, pool *pgxpool.Pool) seed {
	t.Helper()
	ctx := context.Background()

	var creatorID, deptID uuid.UUID
	err := pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ($1, 'x', 'course_creator')
		RETURNING id`, "creator@test.local").Scan(&creatorID)
	require.NoError(t, err)

	err = pool.QueryRow(ctx, `
		INSERT INTO identity.departments (name, leader_id, created_by)
		VALUES ('Test Dept', $1, $1)
		RETURNING id`, creatorID).Scan(&deptID)
	require.NoError(t, err)

	return seed{creatorID: creatorID, deptID: deptID}
}

func newService(t *testing.T, pool *pgxpool.Pool) *catalog.Service {
	t.Helper()
	log := zap.NewNop()
	return catalog.NewService(catalog.NewRepository(pool), events.NewBus(log), log)
}

func TestCreateCourse_AndListByDepartment(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	s := seedIdentity(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	course := &catalog.Course{
		Name:            "Intro Go",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1500000),
		MinPrice:        decimal.NewFromInt(1000000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))
	require.NotEqual(t, uuid.Nil, course.ID)

	got, err := svc.GetCourse(ctx, course.ID)
	require.NoError(t, err)
	require.Equal(t, "Intro Go", got.Name)

	list, err := svc.ListCoursesByDepartment(ctx, s.deptID)
	require.NoError(t, err)
	require.Len(t, list, 1)
}

func TestBatchLifecycle_DraftOpenClosed(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	s := seedIdentity(t, pool)

	svc := newService(t, pool)
	ctx := context.Background()

	course := &catalog.Course{
		Name:            "Course A",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1000000),
		MinPrice:        decimal.NewFromInt(800000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))

	batch := &catalog.CourseBatch{
		CourseID:  course.ID,
		Label:     "Batch 1",
		StartDate: time.Now(),
		EndDate:   time.Now().AddDate(0, 1, 0),
		Price:     decimal.NewFromInt(1200000),
		CreatedBy: s.creatorID,
	}
	require.NoError(t, svc.CreateBatch(ctx, batch))
	require.Equal(t, catalog.BatchDraft, batch.Status)

	require.NoError(t, svc.OpenBatch(ctx, batch.ID))
	got, err := svc.GetBatch(ctx, batch.ID)
	require.NoError(t, err)
	require.Equal(t, catalog.BatchOpen, got.Status)

	// Cannot open an already-open batch
	require.Error(t, svc.OpenBatch(ctx, batch.ID))

	require.NoError(t, svc.CloseBatch(ctx, batch.ID))
	got, err = svc.GetBatch(ctx, batch.ID)
	require.NoError(t, err)
	require.Equal(t, catalog.BatchClosed, got.Status)

	// Closing twice is rejected
	require.Error(t, svc.CloseBatch(ctx, batch.ID))
}
