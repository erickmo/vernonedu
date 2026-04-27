package credentialing

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// CertificateIssuedPayload published when certificate is issued.
type CertificateIssuedPayload struct {
	CertificateID uuid.UUID `json:"certificate_id"`
	EnrollmentID  uuid.UUID `json:"enrollment_id"`
}

// enrollmentCompletedPayload mirrors enrollment.EnrollmentCompletedPayload's
// shape so we can decode without depending on the enrollment package.
type enrollmentCompletedPayload struct {
	EnrollmentID uuid.UUID `json:"enrollment_id"`
}

// RegisterSubscriptions subscribes credentialing to enrollment completion events.
// On EnrollmentCompleted, asynchronously triggers IssueForEnrollment.
// Idempotent: duplicate events for the same enrollment yield a single cert.
func RegisterSubscriptions(bus events.Bus, svc *Service, log *zap.Logger) {
	bus.Subscribe(events.EnrollmentCompleted, func(ctx context.Context, e events.Event) error {
		enrollmentID, err := extractEnrollmentID(e.Payload)
		if err != nil {
			log.Error("credentialing: bad EnrollmentCompleted payload", zap.Error(err))
			return err
		}
		// Async: do not block publisher on PDF generation.
		go func(id uuid.UUID) {
			bgCtx := context.Background()
			if _, err := svc.IssueForEnrollment(bgCtx, id); err != nil {
				log.Error("credentialing: cert issuance failed",
					zap.String("enrollment_id", id.String()), zap.Error(err))
			}
		}(enrollmentID)
		return nil
	})
}

// extractEnrollmentID pulls the enrollment_id from any payload that exposes it,
// supporting both the typed enrollment.EnrollmentCompletedPayload and a
// generic map[string]any (e.g. when the bus is decoupled from typed structs).
func extractEnrollmentID(payload any) (uuid.UUID, error) {
	switch p := payload.(type) {
	case enrollmentCompletedPayload:
		return p.EnrollmentID, nil
	case interface{ GetEnrollmentID() uuid.UUID }:
		return p.GetEnrollmentID(), nil
	case map[string]any:
		if v, ok := p["enrollment_id"].(string); ok {
			return uuid.Parse(v)
		}
	}
	// Fallback: use reflection-friendly field access via JSON shape.
	if id, ok := payloadFieldUUID(payload, "EnrollmentID"); ok {
		return id, nil
	}
	return uuid.Nil, fmt.Errorf("unsupported payload type %T", payload)
}
