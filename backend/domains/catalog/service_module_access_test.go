package catalog

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// seedCourseWithActiveModules creates a course + batch + n active modules
// in the fake repo, returning (courseID, batchID).
func seedCourseWithActiveModules(t *testing.T, repo *fakeCatalogRepo, n int) (uuid.UUID, uuid.UUID) {
	t.Helper()
	creator := uuid.New()
	course := repo.SeedCourse(&Course{
		ID:              uuid.New(),
		Name:            "Test Course",
		DepartmentID:    uuid.New(),
		CourseCreatorID: creator,
		IsActive:        true,
		CreatedBy:       creator,
	})
	batch := repo.SeedBatch(&CourseBatch{
		ID:       uuid.New(),
		CourseID: course.ID,
		Status:   BatchOpen,
	})
	for i := 0; i < n; i++ {
		repo.SeedModule(&CourseModule{
			ID:        uuid.New(),
			CourseID:  course.ID,
			Title:     "Module",
			Order:     i + 1,
			IsActive:  true,
			CreatedBy: creator,
		})
	}
	return course.ID, batch.ID
}

// TestOnEnrollmentConfirmed_GrantsAccess verifies that publishing
// enrollment.confirmed for a batch with two active modules results in two
// student_module_access rows for the student (lifetime, no expiration).
func TestOnEnrollmentConfirmed_GrantsAccess(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	bus := events.NewBus(zap.NewNop())
	svc := NewService(repo, bus, testLogger())
	RegisterSubscriptions(bus, svc)

	_, batchID := seedCourseWithActiveModules(t, repo, 2)
	studentID := uuid.New()

	if err := bus.Publish(ctx, events.Event{
		Type: events.EnrollmentConfirmed,
		Payload: events.EnrollmentConfirmedPayload{
			EnrollmentID: uuid.New(),
			StudentID:    studentID,
			BatchID:      batchID,
		},
	}); err != nil {
		t.Fatalf("publish: unexpected error: %v", err)
	}

	rows, err := repo.ListModuleAccessForStudent(ctx, studentID)
	if err != nil {
		t.Fatalf("list access: %v", err)
	}
	if got := len(rows); got != 2 {
		t.Fatalf("expected 2 access rows, got %d", got)
	}
}

// TestOnEnrollmentConfirmed_NoModules_NoOp verifies that a batch with zero
// active modules grants nothing and does not error.
func TestOnEnrollmentConfirmed_NoModules_NoOp(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	bus := events.NewBus(zap.NewNop())
	svc := NewService(repo, bus, testLogger())
	RegisterSubscriptions(bus, svc)

	_, batchID := seedCourseWithActiveModules(t, repo, 0)
	studentID := uuid.New()

	if err := bus.Publish(ctx, events.Event{
		Type: events.EnrollmentConfirmed,
		Payload: events.EnrollmentConfirmedPayload{
			EnrollmentID: uuid.New(),
			StudentID:    studentID,
			BatchID:      batchID,
		},
	}); err != nil {
		t.Fatalf("publish: unexpected error: %v", err)
	}

	rows, _ := repo.ListModuleAccessForStudent(ctx, studentID)
	if len(rows) != 0 {
		t.Fatalf("expected 0 access rows, got %d", len(rows))
	}
}

// TestOnEnrollmentConfirmed_AlreadyGranted_Idempotent verifies that firing
// the same event twice still results in exactly two rows (UNIQUE constraint
// on (student_id, module_id) absorbs duplicates).
func TestOnEnrollmentConfirmed_AlreadyGranted_Idempotent(t *testing.T) {
	ctx := context.Background()
	repo := newFakeCatalogRepo()
	bus := events.NewBus(zap.NewNop())
	svc := NewService(repo, bus, testLogger())
	RegisterSubscriptions(bus, svc)

	_, batchID := seedCourseWithActiveModules(t, repo, 2)
	studentID := uuid.New()

	evt := events.Event{
		Type: events.EnrollmentConfirmed,
		Payload: events.EnrollmentConfirmedPayload{
			EnrollmentID: uuid.New(),
			StudentID:    studentID,
			BatchID:      batchID,
		},
	}
	for i := 0; i < 2; i++ {
		if err := bus.Publish(ctx, evt); err != nil {
			t.Fatalf("publish #%d: unexpected error: %v", i+1, err)
		}
	}

	rows, _ := repo.ListModuleAccessForStudent(ctx, studentID)
	if got := len(rows); got != 2 {
		t.Fatalf("expected 2 access rows after idempotent fire, got %d", got)
	}
}
