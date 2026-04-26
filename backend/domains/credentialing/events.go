package credentialing

import (
	"context"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// CertificateIssuedPayload published when certificate is issued.
type CertificateIssuedPayload struct {
	CertificateID uuid.UUID `json:"certificate_id"`
	EnrollmentID  uuid.UUID `json:"enrollment_id"`
}

// RegisterSubscriptions subscribes credentialing to enrollment completion.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.EnrollmentCompleted, func(_ context.Context, _ events.Event) error {
		return nil
	})
}
