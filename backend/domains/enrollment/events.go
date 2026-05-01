package enrollment

import (
	"context"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// EnrollmentConfirmedPayload published on successful enrollment creation.
type EnrollmentConfirmedPayload struct {
	EnrollmentID uuid.UUID `json:"enrollment_id"`
	StudentID    uuid.UUID `json:"student_id"`
	BatchID      uuid.UUID `json:"batch_id"`
}

// EnrollmentCompletedPayload published when enrollment is completed.
type EnrollmentCompletedPayload struct {
	EnrollmentID uuid.UUID `json:"enrollment_id"`
}

// EnrollmentDroppedPayload published when enrollment is dropped.
type EnrollmentDroppedPayload struct {
	EnrollmentID uuid.UUID `json:"enrollment_id"`
}

// RegisterSubscriptions subscribes enrollment to cross-domain events.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.PaymentConfirmed, func(_ context.Context, _ events.Event) error {
		return nil
	})
}
