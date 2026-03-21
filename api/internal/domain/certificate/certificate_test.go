package certificate_test

import (
	"strings"
	"testing"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
)

func TestGenerateCertificateCode_Participant(t *testing.T) {
	code := certificate.GenerateCertificateCode(certificate.TypeParticipant)
	if !strings.HasPrefix(code, "VE-P-") {
		t.Errorf("expected code to start with VE-P-, got %s", code)
	}
}

func TestGenerateCertificateCode_Competency(t *testing.T) {
	code := certificate.GenerateCertificateCode(certificate.TypeCompetency)
	if !strings.HasPrefix(code, "VE-C-") {
		t.Errorf("expected code to start with VE-C-, got %s", code)
	}
}

func TestNewCertificate_Valid(t *testing.T) {
	cert, err := certificate.NewCertificate(nil, nil, nil, nil, certificate.TypeParticipant, "")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if cert.Status != certificate.StatusActive {
		t.Errorf("expected status active, got %s", cert.Status)
	}
	if cert.CertificateCode == "" {
		t.Error("expected non-empty certificate code")
	}
	if cert.QRCodeURL == "" {
		t.Error("expected non-empty QR code URL")
	}
}

func TestNewCertificate_InvalidType(t *testing.T) {
	_, err := certificate.NewCertificate(nil, nil, nil, nil, certificate.CertType("invalid"), "")
	if err == nil {
		t.Fatal("expected error for invalid type")
	}
	if err != certificate.ErrInvalidType {
		t.Errorf("expected ErrInvalidType, got %v", err)
	}
}

func TestCertificate_Revoke_Success(t *testing.T) {
	cert, err := certificate.NewCertificate(nil, nil, nil, nil, certificate.TypeParticipant, "")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if err := cert.Revoke("test reason"); err != nil {
		t.Fatalf("expected no error on revoke, got %v", err)
	}

	if cert.Status != certificate.StatusRevoked {
		t.Errorf("expected status revoked, got %s", cert.Status)
	}
	if cert.RevokedAt == nil {
		t.Error("expected RevokedAt to be set")
	}
	if cert.RevocationReason != "test reason" {
		t.Errorf("expected revocation reason 'test reason', got %s", cert.RevocationReason)
	}
}

func TestCertificate_Revoke_AlreadyRevoked(t *testing.T) {
	cert, err := certificate.NewCertificate(nil, nil, nil, nil, certificate.TypeParticipant, "")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if err := cert.Revoke("first reason"); err != nil {
		t.Fatalf("expected no error on first revoke, got %v", err)
	}

	err = cert.Revoke("second reason")
	if err == nil {
		t.Fatal("expected error on second revoke")
	}
	if err != certificate.ErrAlreadyRevoked {
		t.Errorf("expected ErrAlreadyRevoked, got %v", err)
	}
}

func TestNewCertificateTemplate_Valid(t *testing.T) {
	tmpl, err := certificate.NewCertificateTemplate("Test Template", certificate.TypeParticipant, nil)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if tmpl.Name != "Test Template" {
		t.Errorf("expected name 'Test Template', got %s", tmpl.Name)
	}
	if tmpl.Type != certificate.TypeParticipant {
		t.Errorf("expected type participant, got %s", tmpl.Type)
	}
	if !tmpl.IsActive {
		t.Error("expected template to be active")
	}
	if tmpl.TemplateData == nil {
		t.Error("expected non-nil template data")
	}
}

func TestNewCertificateTemplate_EmptyName(t *testing.T) {
	_, err := certificate.NewCertificateTemplate("", certificate.TypeParticipant, nil)
	if err == nil {
		t.Fatal("expected error for empty name")
	}
}
