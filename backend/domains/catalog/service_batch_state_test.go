package catalog

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// helpers --------------------------------------------------------------------

// seedCourseAndBatch wires a course, a draft batch, and (optionally) an
// enabled regular-format config with min_students=minStudents.
func seedCourseAndBatch(
	r *fakeCatalogRepo,
	basePrice, minPrice, batchPrice decimal.Decimal,
	withFormat bool,
	enabled bool,
	minStudents *int,
) (uuid.UUID, uuid.UUID) {
	courseID := uuid.New()
	r.SeedCourse(&Course{
		ID:        courseID,
		Name:      "C1",
		BasePrice: basePrice,
		MinPrice:  minPrice,
	})
	if withFormat {
		_ = r.AddFormatConfig(context.Background(), &CourseFormatConfig{
			ID:          uuid.New(),
			CourseID:    courseID,
			Format:      FormatRegular,
			IsEnabled:   enabled,
			MinStudents: minStudents,
		})
	}
	batchID := uuid.New()
	r.SeedBatch(&CourseBatch{
		ID:        batchID,
		CourseID:  courseID,
		Label:     "B1",
		StartDate: time.Now(),
		EndDate:   time.Now().Add(24 * time.Hour),
		Price:     batchPrice,
		Status:    BatchDraft,
	})
	return courseID, batchID
}

// OpenBatch ------------------------------------------------------------------

func TestOpenBatch_NoFormatEnabled_Rejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	// No format configs at all.
	_, batchID := seedCourseAndBatch(
		repo,
		decimal.NewFromInt(1000), decimal.NewFromInt(500), decimal.NewFromInt(800),
		false, false, nil,
	)

	if err := svc.OpenBatch(context.Background(), batchID); err == nil {
		t.Fatalf("expected error when no enabled format, got nil")
	}
	b, _ := repo.GetBatchByID(context.Background(), batchID)
	if b.Status != BatchDraft {
		t.Fatalf("status = %s, want draft", b.Status)
	}
}

func TestOpenBatch_FormatPresentButDisabled_Rejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	_, batchID := seedCourseAndBatch(
		repo,
		decimal.NewFromInt(1000), decimal.NewFromInt(500), decimal.NewFromInt(800),
		true, false, intPtr(5),
	)

	if err := svc.OpenBatch(context.Background(), batchID); err == nil {
		t.Fatalf("expected error when only disabled format present, got nil")
	}
}

func TestOpenBatch_PriceBelowMin_Rejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	_, batchID := seedCourseAndBatch(
		repo,
		decimal.NewFromInt(1000), decimal.NewFromInt(500), decimal.NewFromInt(400),
		true, true, intPtr(5),
	)

	if err := svc.OpenBatch(context.Background(), batchID); err == nil {
		t.Fatalf("expected error for price below min, got nil")
	}
}

func TestOpenBatch_PriceAboveBase_Rejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	_, batchID := seedCourseAndBatch(
		repo,
		decimal.NewFromInt(1000), decimal.NewFromInt(500), decimal.NewFromInt(1500),
		true, true, intPtr(5),
	)

	if err := svc.OpenBatch(context.Background(), batchID); err == nil {
		t.Fatalf("expected error for price above base, got nil")
	}
}

func TestOpenBatch_PriceInRange_OK(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	_, batchID := seedCourseAndBatch(
		repo,
		decimal.NewFromInt(1000), decimal.NewFromInt(500), decimal.NewFromInt(800),
		true, true, intPtr(5),
	)

	if err := svc.OpenBatch(context.Background(), batchID); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	b, _ := repo.GetBatchByID(context.Background(), batchID)
	if b.Status != BatchOpen {
		t.Fatalf("status = %s, want open", b.Status)
	}
}

// MoveToOngoing --------------------------------------------------------------

func TestMoveToOngoing_BelowMinStudents_Rejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	_, batchID := seedCourseAndBatch(
		repo,
		decimal.NewFromInt(1000), decimal.NewFromInt(500), decimal.NewFromInt(800),
		true, true, intPtr(5),
	)
	// Promote draft → open via state machine.
	if err := svc.OpenBatch(context.Background(), batchID); err != nil {
		t.Fatalf("seed open: %v", err)
	}
	repo.SeedEnrollmentCount(batchID, 3) // below min 5

	if err := svc.MoveToOngoing(context.Background(), batchID); err == nil {
		t.Fatalf("expected error when enrolled < min_students, got nil")
	}
	b, _ := repo.GetBatchByID(context.Background(), batchID)
	if b.Status != BatchOpen {
		t.Fatalf("status = %s, want open (unchanged)", b.Status)
	}
}

func TestMoveToOngoing_OK(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	_, batchID := seedCourseAndBatch(
		repo,
		decimal.NewFromInt(1000), decimal.NewFromInt(500), decimal.NewFromInt(800),
		true, true, intPtr(5),
	)
	if err := svc.OpenBatch(context.Background(), batchID); err != nil {
		t.Fatalf("seed open: %v", err)
	}
	repo.SeedEnrollmentCount(batchID, 5)

	if err := svc.MoveToOngoing(context.Background(), batchID); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	b, _ := repo.GetBatchByID(context.Background(), batchID)
	if b.Status != BatchOngoing {
		t.Fatalf("status = %s, want ongoing", b.Status)
	}
}

func TestMoveToOngoing_FromDraft_Rejected(t *testing.T) {
	repo := newFakeCatalogRepo()
	svc := NewService(repo, newFakeBus(), testLogger())

	_, batchID := seedCourseAndBatch(
		repo,
		decimal.NewFromInt(1000), decimal.NewFromInt(500), decimal.NewFromInt(800),
		true, true, intPtr(5),
	)

	if err := svc.MoveToOngoing(context.Background(), batchID); err == nil {
		t.Fatalf("expected error when moving from draft, got nil")
	}
}

// CloseBatch -----------------------------------------------------------------

func TestCloseBatch_FiresEvent(t *testing.T) {
	repo := newFakeCatalogRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger())

	_, batchID := seedCourseAndBatch(
		repo,
		decimal.NewFromInt(1000), decimal.NewFromInt(500), decimal.NewFromInt(800),
		true, true, intPtr(5),
	)
	// Walk through draft → open → closed (skip ongoing — close is allowed
	// from any non-closed state per CloseBatch contract).
	if err := svc.OpenBatch(context.Background(), batchID); err != nil {
		t.Fatalf("open: %v", err)
	}
	if err := svc.CloseBatch(context.Background(), batchID); err != nil {
		t.Fatalf("close: %v", err)
	}

	b, _ := repo.GetBatchByID(context.Background(), batchID)
	if b.Status != BatchClosed {
		t.Fatalf("status = %s, want closed", b.Status)
	}
	if !bus.Fired(events.BatchClosed) {
		t.Fatalf("expected %s event to be fired", events.BatchClosed)
	}
	payloads := bus.payloads[events.BatchClosed]
	if len(payloads) != 1 {
		t.Fatalf("payload count = %d, want 1", len(payloads))
	}
	p, ok := payloads[0].(events.BatchClosedPayload)
	if !ok {
		t.Fatalf("payload type = %T, want events.BatchClosedPayload", payloads[0])
	}
	if p.BatchID != batchID {
		t.Errorf("payload BatchID = %v, want %v", p.BatchID, batchID)
	}
	if p.CourseID == uuid.Nil {
		t.Errorf("payload CourseID is zero")
	}
}

// CreateBatch ----------------------------------------------------------------

func TestCreateBatch_FiresEventWithCanonicalPayload(t *testing.T) {
	repo := newFakeCatalogRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger())

	courseID := uuid.New()
	repo.SeedCourse(&Course{ID: courseID, Name: "C1"})

	batch, err := svc.CreateBatch(context.Background(), CreateBatchInput{
		CourseID:  courseID,
		Label:     "B1",
		StartDate: time.Now(),
		EndDate:   time.Now().Add(24 * time.Hour),
		Price:     decimal.NewFromInt(1000),
		CreatedBy: uuid.New(),
	})
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	if !bus.Fired(events.BatchCreated) {
		t.Fatalf("expected %s event to be fired", events.BatchCreated)
	}
	payloads := bus.payloads[events.BatchCreated]
	if len(payloads) != 1 {
		t.Fatalf("payload count = %d, want 1", len(payloads))
	}
	p, ok := payloads[0].(events.BatchCreatedPayload)
	if !ok {
		t.Fatalf("payload type = %T, want events.BatchCreatedPayload", payloads[0])
	}
	if p.BatchID != batch.ID {
		t.Errorf("payload BatchID = %v, want %v", p.BatchID, batch.ID)
	}
	if p.CourseID != courseID {
		t.Errorf("payload CourseID = %v, want %v", p.CourseID, courseID)
	}
	if p.Classes == nil {
		t.Errorf("payload.Classes should be non-nil empty slice (calendar contract)")
	}
}
