package enrollment

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// lifecycleSvc builds a Service plus the repo/bus needed for lifecycle tests.
func lifecycleSvc(t *testing.T) (*Service, *fakeEnrollmentRepo, *fakeBus) {
	t.Helper()
	r := newFakeEnrollmentRepo()
	bus := newFakeBus()
	s := NewService(r, bus, testLogger(), newFakeCatalogReader(), newFakePartnershipsReader(), nil)
	return s, r, bus
}

func seedEnrollmentWithStatus(r *fakeEnrollmentRepo, comp CompletionStatus, pay PaymentStatus) *Enrollment {
	e := &Enrollment{
		ID:               uuid.New(),
		StudentID:        uuid.New(),
		CourseBatchID:    uuid.New(),
		Format:           FormatRegular,
		Mode:             ModeOnline,
		Payer:            string(PayerStudent),
		Price:            decimal.NewFromInt(1000),
		FinalPrice:       decimal.NewFromInt(1000),
		PaymentStatus:    pay,
		CompletionStatus: comp,
		Source:           SourceB2C,
	}
	r.SeedEnrollment(e)
	return e
}

// --- MarkCompleted ----------------------------------------------------------

func TestMarkCompleted_FromOngoing_OK_FiresEvent(t *testing.T) {
	s, r, bus := lifecycleSvc(t)
	e := seedEnrollmentWithStatus(r, CompletionOngoing, PaymentPending)

	if err := s.MarkCompleted(context.Background(), e.ID); err != nil {
		t.Fatalf("MarkCompleted: %v", err)
	}

	got, _ := r.GetEnrollmentByID(context.Background(), e.ID)
	if got.CompletionStatus != CompletionCompleted {
		t.Fatalf("completion=%s, want completed", got.CompletionStatus)
	}
	// Payment must not be coerced.
	if got.PaymentStatus != PaymentPending {
		t.Fatalf("payment=%s, want pending (must not be coerced)", got.PaymentStatus)
	}
	if !bus.Fired(events.EnrollmentCompleted) {
		t.Fatalf("expected enrollment.completed event")
	}
	payloads := bus.payloads[events.EnrollmentCompleted]
	if len(payloads) != 1 {
		t.Fatalf("expected 1 payload, got %d", len(payloads))
	}
	p, ok := payloads[0].(events.EnrollmentCompletedPayload)
	if !ok {
		t.Fatalf("payload type=%T, want events.EnrollmentCompletedPayload", payloads[0])
	}
	if p.EnrollmentID != e.ID || p.StudentID != e.StudentID || p.BatchID != e.CourseBatchID {
		t.Fatalf("payload mismatch: %+v", p)
	}
}

func TestMarkCompleted_FromDropped_Rejected(t *testing.T) {
	s, r, bus := lifecycleSvc(t)
	e := seedEnrollmentWithStatus(r, CompletionDropped, PaymentPending)

	err := s.MarkCompleted(context.Background(), e.ID)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	appErr, ok := err.(*apperrors.AppError)
	if !ok || appErr.Code != "VALIDATION_ERROR" {
		t.Fatalf("err=%v, want validation error", err)
	}
	if bus.Fired(events.EnrollmentCompleted) {
		t.Fatalf("no event should fire on rejected transition")
	}
}

func TestMarkCompleted_FromCompleted_Idempotent_NoSecondEvent(t *testing.T) {
	s, r, bus := lifecycleSvc(t)
	e := seedEnrollmentWithStatus(r, CompletionOngoing, PaymentPending)

	if err := s.MarkCompleted(context.Background(), e.ID); err != nil {
		t.Fatalf("first MarkCompleted: %v", err)
	}
	firstCount := len(bus.payloads[events.EnrollmentCompleted])

	if err := s.MarkCompleted(context.Background(), e.ID); err != nil {
		t.Fatalf("second MarkCompleted should be nil, got %v", err)
	}
	secondCount := len(bus.payloads[events.EnrollmentCompleted])

	if firstCount != 1 || secondCount != 1 {
		t.Fatalf("event fired counts first=%d second=%d, want 1 and 1 (idempotent)", firstCount, secondCount)
	}
}

// --- Drop -------------------------------------------------------------------

func TestDrop_FromOngoing_OK_FiresEvent(t *testing.T) {
	s, r, bus := lifecycleSvc(t)
	e := seedEnrollmentWithStatus(r, CompletionOngoing, PaymentPending)

	if err := s.Drop(context.Background(), e.ID); err != nil {
		t.Fatalf("Drop: %v", err)
	}

	got, _ := r.GetEnrollmentByID(context.Background(), e.ID)
	if got.CompletionStatus != CompletionDropped {
		t.Fatalf("completion=%s, want dropped", got.CompletionStatus)
	}
	if !bus.Fired(events.EnrollmentDropped) {
		t.Fatalf("expected enrollment.dropped event")
	}
	payloads := bus.payloads[events.EnrollmentDropped]
	p, ok := payloads[0].(events.EnrollmentDroppedPayload)
	if !ok {
		t.Fatalf("payload type=%T, want events.EnrollmentDroppedPayload", payloads[0])
	}
	if p.EnrollmentID != e.ID || p.StudentID != e.StudentID || p.BatchID != e.CourseBatchID {
		t.Fatalf("payload mismatch: %+v", p)
	}
}

func TestDrop_FromCompleted_Allowed_Logged(t *testing.T) {
	// Admin-override path per certificate spec rule 12: dropping a completed
	// enrollment is allowed but must still emit enrollment.dropped (and is
	// logged as a warning by the service).
	s, r, bus := lifecycleSvc(t)
	e := seedEnrollmentWithStatus(r, CompletionCompleted, PaymentPaid)

	if err := s.Drop(context.Background(), e.ID); err != nil {
		t.Fatalf("Drop should be allowed (admin override), got %v", err)
	}
	got, _ := r.GetEnrollmentByID(context.Background(), e.ID)
	if got.CompletionStatus != CompletionDropped {
		t.Fatalf("completion=%s, want dropped", got.CompletionStatus)
	}
	if !bus.Fired(events.EnrollmentDropped) {
		t.Fatalf("expected enrollment.dropped event on admin override")
	}
}

func TestDrop_FromDropped_Idempotent(t *testing.T) {
	s, r, bus := lifecycleSvc(t)
	e := seedEnrollmentWithStatus(r, CompletionDropped, PaymentPending)

	if err := s.Drop(context.Background(), e.ID); err != nil {
		t.Fatalf("Drop on already-dropped should be nil, got %v", err)
	}
	if bus.Fired(events.EnrollmentDropped) {
		t.Fatalf("no event should fire when idempotent no-op")
	}
}
