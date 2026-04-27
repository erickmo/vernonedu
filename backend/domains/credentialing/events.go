package credentialing

import (
	"context"
	"errors"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// RegisterSubscriptions wires credentialing listeners onto the bus.
//
// On enrollment.completed, the service auto-issues a StudentCertificate for
// every CertificateConfig of the enrolled course whose issued_on='completion'.
// Configs with issued_on='manual' are skipped. The DB-level UNIQUE constraint
// on (enrollment_id, certificate_config_id) makes the listener idempotent —
// duplicate firings surface as apperrors.ErrConflict and are absorbed.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.EnrollmentCompleted, svc.handleEnrollmentCompleted)
}

// handleEnrollmentCompleted is the bus handler bound in RegisterSubscriptions.
// Bad payload types are logged and silently skipped so a single malformed
// publish cannot break the bus.
func (s *Service) handleEnrollmentCompleted(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.EnrollmentCompletedPayload)
	if !ok {
		s.log.Warn("credentialing: unexpected enrollment.completed payload type")
		return nil
	}
	return s.AutoIssueOnCompletion(ctx, p.EnrollmentID, p.StudentID, p.BatchID)
}

// AutoIssueOnCompletion issues every completion-triggered certificate for the
// course bound to the given batch. No-op when catalog reader is unwired or the
// course has no certificate configs. Idempotent: per-config conflicts (already
// issued) are absorbed.
func (s *Service) AutoIssueOnCompletion(ctx context.Context, enrollmentID, studentID, batchID uuid.UUID) error {
	if s.catalog == nil {
		return nil
	}

	courseID, courseTitle, err := s.catalog.GetBatchCourse(ctx, batchID)
	if err != nil {
		return err
	}

	configs, err := s.repo.GetCertificateConfigByCourse(ctx, courseID)
	if err != nil {
		return err
	}

	for _, cfg := range configs {
		if cfg.IssuedOn != IssuedOnCompletion {
			continue
		}
		_, err := s.IssueCertificate(ctx, IssueCertificateInput{
			EnrollmentID:        enrollmentID,
			CertificateConfigID: cfg.ID,
			StudentID:           studentID,
			CourseTitle:         courseTitle,
		})
		if err != nil {
			if errors.Is(err, apperrors.ErrConflict) {
				continue
			}
			s.log.Warn("credentialing: auto-issue cert failed",
				zap.Error(err),
				zap.String("config_id", cfg.ID.String()),
				zap.String("enrollment_id", enrollmentID.String()),
			)
		}
	}
	return nil
}
