package issue_certificate_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/command/issue_certificate"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// mockCertWriteRepo implements certificate.WriteRepository for testing
type mockCertWriteRepo struct {
	saved *certificate.Certificate
}

func (m *mockCertWriteRepo) Save(ctx context.Context, c *certificate.Certificate) error {
	m.saved = c
	return nil
}

func (m *mockCertWriteRepo) SaveTemplate(ctx context.Context, t *certificate.CertificateTemplate) error {
	return nil
}

func (m *mockCertWriteRepo) UpdateTemplate(ctx context.Context, t *certificate.CertificateTemplate) error {
	return nil
}

func (m *mockCertWriteRepo) Revoke(ctx context.Context, id uuid.UUID, reason string, revokedAt time.Time) error {
	return nil
}

func TestIssueCertificateHandler_Success(t *testing.T) {
	repo := &mockCertWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := issue_certificate.NewHandler(repo, bus)

	cmd := &issue_certificate.IssueCertificateCommand{
		TemplateID:          uuid.New().String(),
		StudentID:           uuid.New().String(),
		BatchID:             "",
		CourseID:            "",
		Type:                "participant",
		VerificationBaseURL: "https://vernonedu.id/verify",
	}

	err := handler.Handle(context.Background(), cmd)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if repo.saved == nil {
		t.Fatal("expected certificate to be saved")
	}
	if repo.saved.Status != certificate.StatusActive {
		t.Errorf("expected status active, got %s", repo.saved.Status)
	}
	if repo.saved.CertificateCode == "" {
		t.Error("expected non-empty certificate code")
	}
}

func TestIssueCertificateHandler_InvalidType(t *testing.T) {
	repo := &mockCertWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := issue_certificate.NewHandler(repo, bus)

	cmd := &issue_certificate.IssueCertificateCommand{
		TemplateID: uuid.New().String(),
		Type:       "invalid_type",
	}

	err := handler.Handle(context.Background(), cmd)
	if err == nil {
		t.Fatal("expected error for invalid type")
	}
}
