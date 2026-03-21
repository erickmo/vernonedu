package verify_certificate_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
	"github.com/vernonedu/entrepreneurship-api/internal/query/verify_certificate"
)

// mockCertReadRepo implements certificate.ReadRepository for testing
type mockCertReadRepo struct {
	certs map[string]*certificate.Certificate
}

func newMockCertReadRepo() *mockCertReadRepo {
	return &mockCertReadRepo{certs: make(map[string]*certificate.Certificate)}
}

func (m *mockCertReadRepo) GetByCode(ctx context.Context, code string) (*certificate.Certificate, error) {
	c, ok := m.certs[code]
	if !ok {
		return nil, certificate.ErrCertificateNotFound
	}
	return c, nil
}

func (m *mockCertReadRepo) GetByID(ctx context.Context, id uuid.UUID) (*certificate.Certificate, error) {
	return nil, certificate.ErrCertificateNotFound
}

func (m *mockCertReadRepo) GetTemplateByID(ctx context.Context, id uuid.UUID) (*certificate.CertificateTemplate, error) {
	return nil, certificate.ErrTemplateNotFound
}

func (m *mockCertReadRepo) ListTemplates(ctx context.Context) ([]*certificate.CertificateTemplate, error) {
	return nil, nil
}

func (m *mockCertReadRepo) List(ctx context.Context, studentID, batchID *uuid.UUID, certType, status string, offset, limit int) ([]*certificate.Certificate, int, error) {
	return nil, 0, nil
}

func makeCert(certType certificate.CertType, status certificate.Status) *certificate.Certificate {
	now := time.Now()
	c := &certificate.Certificate{
		ID:              uuid.New(),
		Type:            certType,
		CertificateCode: "VE-P-2026-TESTCODE",
		QRCodeURL:       "https://vernonedu.id/verify/VE-P-2026-TESTCODE",
		Status:          status,
		IssuedAt:        now,
		CreatedAt:       now,
		UpdatedAt:       now,
	}
	if status == certificate.StatusRevoked {
		t := now
		c.RevokedAt = &t
		c.RevocationReason = "test revocation"
	}
	return c
}

func TestVerifyHandler_ActiveCertificate(t *testing.T) {
	repo := newMockCertReadRepo()
	cert := makeCert(certificate.TypeParticipant, certificate.StatusActive)
	repo.certs[cert.CertificateCode] = cert

	handler := verify_certificate.NewHandler(repo)
	result, err := handler.Handle(context.Background(), &verify_certificate.VerifyCertificateQuery{Code: cert.CertificateCode})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	vr, ok := result.(*verify_certificate.VerifyResult)
	if !ok {
		t.Fatal("expected *VerifyResult")
	}
	if !vr.IsValid {
		t.Error("expected IsValid=true")
	}
	if vr.IsRevoked {
		t.Error("expected IsRevoked=false")
	}
}

func TestVerifyHandler_RevokedCertificate(t *testing.T) {
	repo := newMockCertReadRepo()
	cert := makeCert(certificate.TypeParticipant, certificate.StatusRevoked)
	repo.certs[cert.CertificateCode] = cert

	handler := verify_certificate.NewHandler(repo)
	result, err := handler.Handle(context.Background(), &verify_certificate.VerifyCertificateQuery{Code: cert.CertificateCode})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	vr, ok := result.(*verify_certificate.VerifyResult)
	if !ok {
		t.Fatal("expected *VerifyResult")
	}
	if vr.IsValid {
		t.Error("expected IsValid=false")
	}
	if !vr.IsRevoked {
		t.Error("expected IsRevoked=true")
	}
	if vr.RevocationReason != "test revocation" {
		t.Errorf("expected revocation reason 'test revocation', got %s", vr.RevocationReason)
	}
}

func TestVerifyHandler_NotFound(t *testing.T) {
	repo := newMockCertReadRepo()

	handler := verify_certificate.NewHandler(repo)
	_, err := handler.Handle(context.Background(), &verify_certificate.VerifyCertificateQuery{Code: "NONEXISTENT"})
	if err == nil {
		t.Fatal("expected error for non-existent certificate")
	}
	if err != certificate.ErrCertificateNotFound {
		t.Errorf("expected ErrCertificateNotFound, got %v", err)
	}
}
