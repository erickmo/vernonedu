package credentialing

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Verification URL template — caller-relative path used in PDFs.
const verificationPathFmt = "/api/v1/certificates/verify/%s"

// PDFRenderer renders certificate PDF bytes from raw fields.
// Defined here so the service depends on a port, not on internal/worker.
type PDFRenderer interface {
	Render(studentName, courseName, certNumber string, issuedAt time.Time, verificationURL string) ([]byte, error)
}

// CertStorage persists rendered PDF bytes for a given certificate ID.
type CertStorage interface {
	Save(certID uuid.UUID, data []byte) (path string, err error)
}

// Service holds credentialing business logic.
type Service struct {
	repo    Repository
	bus     events.Bus
	log     *zap.Logger
	pdfGen  PDFRenderer
	storage CertStorage
	baseURL string
}

// NewService constructs credentialing Service. pdfGen, storage and baseURL may be
// nil/empty in deployments that do not need PDF issuance (e.g. read-only API).
func NewService(repo Repository, bus events.Bus, log *zap.Logger, pdfGen PDFRenderer, storage CertStorage, baseURL string) *Service {
	return &Service{repo: repo, bus: bus, log: log, pdfGen: pdfGen, storage: storage, baseURL: baseURL}
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

// IssueForEnrollment issues (or returns existing) a certificate for a completed
// enrollment. Idempotent: a non-revoked cert for the same enrollment is returned
// as-is. Renders the PDF, hashes its bytes (SHA-256), stores both, then emits
// CertificateIssued.
func (s *Service) IssueForEnrollment(ctx context.Context, enrollmentID uuid.UUID) (*Certificate, error) {
	if existing, err := s.repo.GetActiveCertificateByEnrollment(ctx, enrollmentID); err == nil {
		return existing, nil
	} else if !errors.Is(err, apperrors.ErrNotFound) {
		return nil, err
	}

	cfg, err := s.repo.GetCertificateConfigForEnrollment(ctx, enrollmentID)
	if err != nil {
		return nil, fmt.Errorf("issue: cert config lookup: %w", err)
	}
	cctx, err := s.repo.GetCertificateContext(ctx, enrollmentID)
	if err != nil {
		return nil, fmt.Errorf("issue: cert context lookup: %w", err)
	}
	cert, err := s.persistInitialCertificate(ctx, enrollmentID, cfg)
	if err != nil {
		return nil, err
	}
	if err := s.renderAndStorePDF(ctx, cert, cctx); err != nil {
		return nil, err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.CertificateIssued,
		Payload: CertificateIssuedPayload{CertificateID: cert.ID, EnrollmentID: enrollmentID},
	})
	return cert, nil
}

func (s *Service) persistInitialCertificate(ctx context.Context, enrollmentID uuid.UUID, cfg *CertificateConfig) (*Certificate, error) {
	certType, err := s.repo.GetCertificateTypeByID(ctx, cfg.CertificateTypeID)
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
		CertificateTypeID:   cfg.CertificateTypeID,
		CertificateConfigID: cfg.ID,
		CertificateNumber:   generateCertNumber(),
		Status:              CertPending,
		ExpiresAt:           expiresAt,
	}
	if err := s.repo.CreateCertificate(ctx, cert); err != nil {
		return nil, err
	}
	return cert, nil
}

func (s *Service) renderAndStorePDF(ctx context.Context, cert *Certificate, cctx *CertificateContext) error {
	if s.pdfGen == nil || s.storage == nil {
		return apperrors.Validationf("pdf generator or storage not configured")
	}
	verifyURL := s.baseURL + fmt.Sprintf(verificationPathFmt, cert.CertificateNumber)
	pdfBytes, err := s.pdfGen.Render(cctx.StudentName, cctx.CourseName, cert.CertificateNumber, cctx.CompletedAt, verifyURL)
	if err != nil {
		return fmt.Errorf("issue: pdf render: %w", err)
	}
	finalHash := sha256Hex(pdfBytes)
	path, err := s.storage.Save(cert.ID, pdfBytes)
	if err != nil {
		return fmt.Errorf("issue: storage save: %w", err)
	}
	if err := s.repo.UpdateCertificatePDF(ctx, cert.ID, path, finalHash); err != nil {
		return err
	}
	cert.PDFPath = &path
	cert.PDFHash = &finalHash
	cert.Status = CertIssued
	return nil
}

func sha256Hex(data []byte) string {
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}

// VerifyByHash returns a public verification result for the given PDF hash.
func (s *Service) VerifyByHash(ctx context.Context, hash string) (*VerificationResult, error) {
	cert, err := s.repo.GetCertificateByHash(ctx, hash)
	if err != nil {
		return nil, err
	}
	if cert.Status == CertRevoked {
		return nil, apperrors.NotFoundf("certificate has been revoked")
	}
	cctx, err := s.repo.GetCertificateContext(ctx, cert.EnrollmentID)
	if err != nil {
		return nil, err
	}
	return &VerificationResult{
		Valid:         true,
		CertificateID: cert.ID,
		Number:        cert.CertificateNumber,
		StudentName:   cctx.StudentName,
		CourseName:    cctx.CourseName,
		IssuedAt:      cert.IssuedAt,
	}, nil
}

// GetCertificateForDownload returns the certificate metadata; caller is expected
// to read the file at PDFPath.
func (s *Service) GetCertificateForDownload(ctx context.Context, id uuid.UUID) (*Certificate, error) {
	cert, err := s.repo.GetCertificateByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if cert.PDFPath == nil {
		return nil, apperrors.NotFoundf("certificate pdf not yet generated")
	}
	return cert, nil
}
