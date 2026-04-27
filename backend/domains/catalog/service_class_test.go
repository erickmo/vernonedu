package catalog

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// isValidationErr returns true if err is an *apperrors.AppError with the
// VALIDATION_ERROR code.
func isValidationErr(err error) bool {
	var ae *apperrors.AppError
	if !errors.As(err, &ae) {
		return false
	}
	return ae.Code == "VALIDATION_ERROR"
}

// classBaseInput returns a baseline CreateClassInput for offline + course_creator.
func classBaseInput(batchID, instructorID uuid.UUID) CreateClassInput {
	loc := "Jakarta HQ"
	return CreateClassInput{
		CourseBatchID:  batchID,
		SessionDate:    time.Date(2026, 5, 1, 0, 0, 0, 0, time.UTC),
		StartTime:      "09:00",
		EndTime:        "12:00",
		Mode:           ModeOffline,
		Location:       &loc,
		InstructorID:   instructorID,
		InstructorType: InstructorCourseCreator,
		AssignedBy:     AssignedByCourseCreatorSelf,
	}
}

func TestCreateClass_OfflineRequiresLocation(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())
	in := classBaseInput(uuid.New(), uuid.New())
	in.Location = nil

	if _, err := svc.CreateClass(context.Background(), in); !isValidationErr(err) {
		t.Fatalf("expected validation error, got %v", err)
	}
}

func TestCreateClass_OnlineRequiresOnlineLink(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())
	in := classBaseInput(uuid.New(), uuid.New())
	in.Mode = ModeOnline
	in.Location = nil
	in.OnlineLink = nil

	if _, err := svc.CreateClass(context.Background(), in); !isValidationErr(err) {
		t.Fatalf("expected validation error, got %v", err)
	}
}

func TestAssignInstructor_BySelfCourseCreator_OK(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())
	classID := uuid.New()
	creatorID := uuid.New()
	repo.classes[classID] = &Class{ID: classID}

	if err := svc.AssignInstructor(context.Background(), classID, creatorID, InstructorCourseCreator, AssignedByCourseCreatorSelf); err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	cl := repo.classes[classID]
	if cl.AssignedBy != AssignedByCourseCreatorSelf {
		t.Fatalf("assigned_by=%q want course_creator_self", cl.AssignedBy)
	}
	if cl.InstructorID != creatorID {
		t.Fatalf("instructor not stored")
	}
}

func TestAssignInstructor_ByDeptLeader_OverridesPrevious(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())
	classID := uuid.New()
	previous := uuid.New()
	next := uuid.New()
	repo.classes[classID] = &Class{
		ID:             classID,
		InstructorID:   previous,
		InstructorType: InstructorCourseCreator,
		AssignedBy:     AssignedByCourseCreatorSelf,
	}
	repo.SeedApprovedFacilitator(next)

	if err := svc.AssignInstructor(context.Background(), classID, next, InstructorFacilitator, AssignedByDeptLeader); err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	cl := repo.classes[classID]
	if cl.InstructorID != next {
		t.Fatalf("override failed: instructor=%v", cl.InstructorID)
	}
	if cl.AssignedBy != AssignedByDeptLeader {
		t.Fatalf("assigned_by=%q want dept_leader", cl.AssignedBy)
	}
}

func TestAssignInstructor_NonApprovedFacilitator_Rejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())
	classID := uuid.New()
	repo.classes[classID] = &Class{ID: classID}

	err := svc.AssignInstructor(context.Background(), classID, uuid.New(), InstructorFacilitator, AssignedByDeptLeader)
	if !isValidationErr(err) {
		t.Fatalf("expected validation error, got %v", err)
	}
}

func TestAssignInstructor_NotIsFacilitator_Rejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())
	classID := uuid.New()
	repo.classes[classID] = &Class{ID: classID}

	// User has no facilitator profile / proposal.
	err := svc.AssignInstructor(context.Background(), classID, uuid.New(), InstructorFacilitator, AssignedByCourseCreatorSelf)
	if !isValidationErr(err) {
		t.Fatalf("expected validation error, got %v", err)
	}
}

func TestRescheduleClass_FiresEvent(t *testing.T) {
	repo := newFakeCatalogRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger())
	classID := uuid.New()
	repo.classes[classID] = &Class{ID: classID}

	newDate := time.Date(2026, 6, 15, 0, 0, 0, 0, time.UTC)
	if err := svc.RescheduleClass(context.Background(), classID, newDate, "10:00", "13:00"); err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	if !bus.Fired(events.ClassRescheduled) {
		t.Fatalf("expected ClassRescheduled event")
	}
	payload := bus.payloads[events.ClassRescheduled][0].(events.ClassRescheduledPayload)
	if payload.ClassID != classID {
		t.Fatalf("class_id mismatch")
	}
	wantStart := time.Date(2026, 6, 15, 10, 0, 0, 0, time.UTC)
	wantEnd := time.Date(2026, 6, 15, 13, 0, 0, 0, time.UTC)
	if !payload.StartAt.Equal(wantStart) {
		t.Fatalf("start_at=%v want %v", payload.StartAt, wantStart)
	}
	if !payload.EndAt.Equal(wantEnd) {
		t.Fatalf("end_at=%v want %v", payload.EndAt, wantEnd)
	}
}

func TestCancelClass_FiresEvent(t *testing.T) {
	repo := newFakeCatalogRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger())
	classID := uuid.New()
	repo.classes[classID] = &Class{ID: classID}

	if err := svc.CancelClass(context.Background(), classID); err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	if !bus.Fired(events.ClassCancelled) {
		t.Fatalf("expected ClassCancelled event")
	}
	if _, exists := repo.classes[classID]; exists {
		t.Fatalf("class should be deleted")
	}
}

func TestAssignFacilitator_FiresEvent(t *testing.T) {
	repo := newFakeCatalogRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger())
	classID := uuid.New()
	facilitatorID := uuid.New()
	repo.classes[classID] = &Class{ID: classID}
	repo.SeedApprovedFacilitator(facilitatorID)

	if err := svc.AssignInstructor(context.Background(), classID, facilitatorID, InstructorFacilitator, AssignedByDeptLeader); err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	if !bus.Fired(events.ClassFacilitatorAssigned) {
		t.Fatalf("expected ClassFacilitatorAssigned event")
	}
	payload := bus.payloads[events.ClassFacilitatorAssigned][0].(events.ClassFacilitatorAssignedPayload)
	if payload.ClassID != classID || payload.FacilitatorID != facilitatorID {
		t.Fatalf("payload mismatch: %+v", payload)
	}
}

// keep reference to errors package for IsValidation guard usage
var _ = errors.New
