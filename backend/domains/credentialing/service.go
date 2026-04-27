package credentialing

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service holds credentialing business logic.
type Service struct {
	repo    Repository
	bus     events.Bus
	log     *zap.Logger
	catalog CatalogReader
}

// NewService constructs credentialing Service.
//
// catalog is used by the enrollment.completed listener to resolve the course
// (id + title) from the batch id carried in the event payload. It may be nil —
// in that case auto-issue on completion is skipped silently.
func NewService(repo Repository, bus events.Bus, log *zap.Logger, catalog CatalogReader) *Service {
	return &Service{repo: repo, bus: bus, log: log, catalog: catalog}
}

// IssueCertificateInput captures the inputs needed to issue a certificate.
// CertificateConfigID determines the certificate_type_id (and thus
// validity_months) via the certificate_configs FK. StudentID and CourseTitle
// are propagated to the canonical events.CertificateIssuedPayload for
// downstream notification fan-out (caller resolves these).
type IssueCertificateInput struct {
	EnrollmentID        uuid.UUID
	CertificateConfigID uuid.UUID
	StudentID           uuid.UUID
	CourseTitle         string
}

// verifyEndpointPrefix is the public verification URL prefix encoded into the
// QR code of every issued certificate.
const verifyEndpointPrefix = "/cert/verify/"

// IssueCertificate issues a new certificate for a completed enrollment.
//
// It resolves the certificate type from the configured certificate_config,
// allocates the next per-year certificate number, derives the expiry date
// from validity_months (NULL → no expiry), and publishes the canonical
// events.CertificateIssuedPayload.
//
// Repository duplicate-key violations on (enrollment_id, certificate_config_id)
// are surfaced as apperrors.ErrConflict.
func (s *Service) IssueCertificate(ctx context.Context, in IssueCertificateInput) (*Certificate, error) {
	cfg, err := s.repo.GetCertificateConfigByID(ctx, in.CertificateConfigID)
	if err != nil {
		return nil, err
	}
	certType, err := s.repo.GetCertificateTypeByID(ctx, cfg.CertificateTypeID)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	number, err := s.repo.NextCertificateNumber(ctx, now.Year())
	if err != nil {
		return nil, err
	}

	var expiresAt *time.Time
	if certType.ValidityMonths != nil {
		exp := now.AddDate(0, *certType.ValidityMonths, 0)
		expiresAt = &exp
	}

	qrURL := verifyEndpointPrefix + number
	cert := &Certificate{
		ID:                  uuid.New(),
		EnrollmentID:        in.EnrollmentID,
		CertificateTypeID:   certType.ID,
		CertificateConfigID: cfg.ID,
		CertificateNumber:   number,
		IssuedAt:            now,
		Status:              CertIssued,
		ExpiresAt:           expiresAt,
		QRCodeURL:           &qrURL,
	}

	if err := s.repo.CreateCertificate(ctx, cert); err != nil {
		return nil, err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type: events.CertificateIssued,
		Payload: events.CertificateIssuedPayload{
			CertificateID:     cert.ID,
			CertificateNumber: cert.CertificateNumber,
			StudentID:         in.StudentID,
			EnrollmentID:      in.EnrollmentID,
			CourseTitle:       in.CourseTitle,
		},
	})

	return cert, nil
}

// VerifyCertificate verifies a certificate by number.
func (s *Service) VerifyCertificate(ctx context.Context, number string) (*Certificate, error) {
	cert, err := s.repo.GetCertificateByNumber(ctx, number)
	if err != nil {
		return nil, err
	}
	if cert.Status == CertRevoked {
		return nil, apperrors.Validationf("certificate has been revoked")
	}
	if cert.ExpiresAt != nil && time.Now().After(*cert.ExpiresAt) {
		return nil, apperrors.Validationf("certificate has expired")
	}
	return cert, nil
}

// ListCertificatesByEnrollment returns certificates for an enrollment.
func (s *Service) ListCertificatesByEnrollment(ctx context.Context, enrollmentID uuid.UUID) ([]*Certificate, error) {
	return s.repo.ListCertificatesByEnrollment(ctx, enrollmentID)
}

// RequestAction creates a revoke or reissue request.
func (s *Service) RequestAction(ctx context.Context, certID uuid.UUID, action CertAction, reason string, requestedBy uuid.UUID) (*CertificateActionRequest, error) {
	cert, err := s.repo.GetCertificateByID(ctx, certID)
	if err != nil {
		return nil, err
	}

	if action == ActionRevoke && cert.Status == CertRevoked {
		return nil, apperrors.Validationf("certificate already revoked")
	}

	req := &CertificateActionRequest{
		ID:                  uuid.New(),
		StudentCertificateID: cert.ID,
		Action:              action,
		Reason:              reason,
		RequestedBy:         requestedBy,
		Status:              ActionPending,
	}

	if err := s.repo.CreateActionRequest(ctx, req); err != nil {
		return nil, err
	}
	return req, nil
}

// ApproveActionRequest approves a cert action request and applies it.
func (s *Service) ApproveActionRequest(ctx context.Context, reqID uuid.UUID, approverID uuid.UUID) error {
	req, err := s.repo.GetActionRequestByID(ctx, reqID)
	if err != nil {
		return err
	}
	if req.Status != ActionPending {
		return apperrors.Validationf("request is not pending")
	}

	if err := s.repo.UpdateActionRequestStatus(ctx, reqID, ActionApproved, &approverID); err != nil {
		return err
	}

	switch req.Action {
	case ActionRevoke:
		return s.repo.UpdateCertificateStatus(ctx, req.StudentCertificateID, CertRevoked)
	case ActionReissue:
		// Original revoked, new cert issued via IssueCertificate (caller handles)
		return s.repo.UpdateCertificateStatus(ctx, req.StudentCertificateID, CertRevoked)
	}
	return nil
}

