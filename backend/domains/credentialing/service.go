package credentialing

import (
	"context"
	"time"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// Public verify response status values. "expired" is a derived state computed
// from expires_at vs now; it is never persisted on the certificate row.
const (
	VerifyStatusIssued  = "issued"
	VerifyStatusExpired = "expired"
	VerifyStatusRevoked = "revoked"
)

// VerifyResult is the public verification view of a certificate. It carries
// authoritative display data (resolved across domains) and a derived status
// suitable for public consumption.
type VerifyResult struct {
	CertificateNumber string
	StudentName       string
	CourseTitle       string
	CertificateType   string
	PartnerName       *string
	IssuedAt          time.Time
	ExpiresAt         *time.Time
	Status            string
	RevokedAt         *time.Time
}

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

// Verify resolves the public verification view for a certificate number.
//
// It looks up the certificate, the cross-domain display context (student name,
// course title, optional partner name), and the certificate type name; then
// returns a VerifyResult with a derived status:
//   - "revoked" when the row is revoked,
//   - "expired" when the row is issued but expires_at has passed,
//   - "issued" otherwise.
//
// The "expired" state is purely derived; the certificate row is not mutated.
// Returns apperrors.ErrNotFound when the number is unknown.
func (s *Service) Verify(ctx context.Context, number string) (*VerifyResult, error) {
	cert, err := s.repo.GetCertificateByNumber(ctx, number)
	if err != nil {
		return nil, err
	}

	if s.catalog == nil {
		return nil, apperrors.Validationf("verification context unavailable")
	}
	info, err := s.catalog.ResolveCertContext(ctx, cert.EnrollmentID)
	if err != nil {
		return nil, err
	}

	ct, err := s.repo.GetCertificateTypeByID(ctx, cert.CertificateTypeID)
	if err != nil {
		return nil, err
	}

	status := VerifyStatusIssued
	switch cert.Status {
	case CertRevoked:
		status = VerifyStatusRevoked
	case CertIssued:
		if cert.ExpiresAt != nil && cert.ExpiresAt.Before(time.Now()) {
			status = VerifyStatusExpired
		}
	}

	return &VerifyResult{
		CertificateNumber: cert.CertificateNumber,
		StudentName:       info.StudentName,
		CourseTitle:       info.CourseTitle,
		CertificateType:   ct.Name,
		PartnerName:       info.PartnerName,
		IssuedAt:          cert.IssuedAt,
		ExpiresAt:         cert.ExpiresAt,
		Status:            status,
		RevokedAt:         cert.RevokedAt,
	}, nil
}

// ListCertificatesByEnrollment returns certificates for an enrollment.
func (s *Service) ListCertificatesByEnrollment(ctx context.Context, enrollmentID uuid.UUID) ([]*Certificate, error) {
	return s.repo.ListCertificatesByEnrollment(ctx, enrollmentID)
}

// RequestActionInput captures inputs to open a revoke/reissue approval request.
type RequestActionInput struct {
	StudentCertificateID uuid.UUID
	Action               CertAction
	Reason               string
	RequestedBy          uuid.UUID
}

// RequestAction opens a pending CertificateActionRequest for an existing
// certificate. The certificate must exist; action must be revoke|reissue;
// reason must be non-empty.
func (s *Service) RequestAction(ctx context.Context, in RequestActionInput) (*CertificateActionRequest, error) {
	if _, err := s.repo.GetCertificateByID(ctx, in.StudentCertificateID); err != nil {
		return nil, err
	}
	if in.Action != ActionRevoke && in.Action != ActionReissue {
		return nil, apperrors.Validationf("invalid action")
	}
	if in.Reason == "" {
		return nil, apperrors.Validationf("reason required")
	}

	req := &CertificateActionRequest{
		ID:                   uuid.New(),
		StudentCertificateID: in.StudentCertificateID,
		Action:               in.Action,
		Reason:               in.Reason,
		RequestedBy:          in.RequestedBy,
		Status:               ActionPending,
	}
	if err := s.repo.CreateActionRequest(ctx, req); err != nil {
		return nil, err
	}
	return req, nil
}

// ApproveAction approves a pending action request and applies the
// corresponding certificate state change (revoke or reissue). Idempotency is
// enforced: an already-resolved request returns a validation error.
func (s *Service) ApproveAction(ctx context.Context, requestID, approverID uuid.UUID) error {
	req, err := s.repo.GetActionRequestByID(ctx, requestID)
	if err != nil {
		return err
	}
	if req.Status != ActionPending {
		return apperrors.Validationf("action already resolved")
	}

	switch req.Action {
	case ActionRevoke:
		if err := s.repo.RevokeCertificate(ctx, req.StudentCertificateID, approverID); err != nil {
			return err
		}
	case ActionReissue:
		if _, err := s.repo.ReissueCertificate(ctx, req.StudentCertificateID, approverID); err != nil {
			return err
		}
	default:
		return apperrors.Validationf("invalid action")
	}

	return s.repo.UpdateActionRequestStatus(ctx, requestID, ActionApproved, &approverID)
}

// RejectAction marks a pending action request as rejected. The certificate is
// not modified.
func (s *Service) RejectAction(ctx context.Context, requestID, reviewerID uuid.UUID) error {
	req, err := s.repo.GetActionRequestByID(ctx, requestID)
	if err != nil {
		return err
	}
	if req.Status != ActionPending {
		return apperrors.Validationf("action already resolved")
	}
	return s.repo.UpdateActionRequestStatus(ctx, requestID, ActionRejected, &reviewerID)
}

