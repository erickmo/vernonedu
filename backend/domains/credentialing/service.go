package credentialing

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service holds credentialing business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs credentialing Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// IssueCertificate creates a certificate for a completed enrollment.
func (s *Service) IssueCertificate(ctx context.Context, enrollmentID, certTypeID, certConfigID uuid.UUID) (*Certificate, error) {
	certType, err := s.repo.GetCertificateTypeByID(ctx, certTypeID)
	if err != nil {
		return nil, err
	}

	var expiresAt *time.Time
	if certType.ValidityMonths != nil {
		exp := time.Now().AddDate(0, *certType.ValidityMonths, 0)
		expiresAt = &exp
	}

	cert := &Certificate{
		ID:                  uuid.New(),
		EnrollmentID:        enrollmentID,
		CertificateTypeID:   certTypeID,
		CertificateConfigID: certConfigID,
		CertificateNumber:   generateCertNumber(),
		Status:              CertIssued,
		ExpiresAt:           expiresAt,
	}

	if err := s.repo.CreateCertificate(ctx, cert); err != nil {
		return nil, err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.CertificateIssued,
		Payload: CertificateIssuedPayload{CertificateID: cert.ID, EnrollmentID: enrollmentID},
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

func generateCertNumber() string {
	return fmt.Sprintf("VE-%d-%s", time.Now().Year(), uuid.New().String()[:8])
}
