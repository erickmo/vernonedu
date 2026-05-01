package catalog

import (
	"context"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// BatchCreatedPayload is published when a batch is created.
type BatchCreatedPayload struct {
	BatchID  uuid.UUID `json:"batch_id"`
	CourseID uuid.UUID `json:"course_id"`
	ActorID  uuid.UUID `json:"actor_id"`
}

// BatchClosedPayload is published when a batch is closed.
type BatchClosedPayload struct {
	BatchID  uuid.UUID `json:"batch_id"`
	CourseID uuid.UUID `json:"course_id"`
}

// ClassFacilitatorAssignedPayload is published when a facilitator is assigned to a class.
type ClassFacilitatorAssignedPayload struct {
	ClassID       uuid.UUID `json:"class_id"`
	FacilitatorID uuid.UUID `json:"facilitator_id"`
}

// ClassRescheduledPayload is published when a class is rescheduled.
type ClassRescheduledPayload struct {
	ClassID uuid.UUID `json:"class_id"`
}

// RegisterSubscriptions subscribes catalog to relevant cross-domain events.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.EnrollmentCompleted, func(_ context.Context, _ events.Event) error {
		return nil
	})
}
