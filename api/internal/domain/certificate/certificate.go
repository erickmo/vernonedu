package certificate

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrCertificateNotFound = errors.New("certificate not found")
	ErrAlreadyRevoked      = errors.New("certificate already revoked")
	ErrInvalidType         = errors.New("invalid certificate type")
	ErrTemplateNotFound    = errors.New("certificate template not found")
	ErrInvalidCode         = errors.New("invalid certificate code")
)

type CertType string

const (
	TypeParticipant CertType = "participant"
	TypeCompetency  CertType = "competency"
)

type Status string

const (
	StatusActive  Status = "active"
	StatusRevoked Status = "revoked"
)

type CertificateTemplate struct {
	ID           uuid.UUID
	Name         string
	Type         CertType
	TemplateData map[string]interface{}
	IsActive     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

func NewCertificateTemplate(name string, certType CertType, templateData map[string]interface{}) (*CertificateTemplate, error) {
	if name == "" {
		return nil, errors.New("template name is required")
	}
	if certType != TypeParticipant && certType != TypeCompetency {
		return nil, ErrInvalidType
	}
	if templateData == nil {
		templateData = map[string]interface{}{}
	}
	return &CertificateTemplate{
		ID:           uuid.New(),
		Name:         name,
		Type:         certType,
		TemplateData: templateData,
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}, nil
}

type Certificate struct {
	ID               uuid.UUID
	TemplateID       *uuid.UUID
	StudentID        *uuid.UUID
	BatchID          *uuid.UUID
	CourseID         *uuid.UUID
	Type             CertType
	CertificateCode  string
	QRCodeURL        string
	Status           Status
	RevokedAt        *time.Time
	RevocationReason string
	IssuedAt         time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

// GenerateCertificateCode generates a unique, human-readable certificate code.
// Format: VE-{TYPE_PREFIX}-{YEAR}-{8RANDOM_ALPHANUM}
// Example: VE-P-2026-AB12CD34
func GenerateCertificateCode(certType CertType) string {
	prefix := "P"
	if certType == TypeCompetency {
		prefix = "C"
	}
	year := time.Now().Year()
	const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var sb strings.Builder
	for i := 0; i < 8; i++ {
		sb.WriteByte(chars[rand.Intn(len(chars))])
	}
	return fmt.Sprintf("VE-%s-%d-%s", prefix, year, sb.String())
}

func NewCertificate(
	templateID *uuid.UUID,
	studentID *uuid.UUID,
	batchID *uuid.UUID,
	courseID *uuid.UUID,
	certType CertType,
	verificationBaseURL string,
) (*Certificate, error) {
	if certType != TypeParticipant && certType != TypeCompetency {
		return nil, ErrInvalidType
	}

	code := GenerateCertificateCode(certType)
	if verificationBaseURL == "" {
		verificationBaseURL = "https://vernonedu.id/verify"
	}
	qrURL := fmt.Sprintf("%s/%s", strings.TrimRight(verificationBaseURL, "/"), code)

	now := time.Now()
	return &Certificate{
		ID:              uuid.New(),
		TemplateID:      templateID,
		StudentID:       studentID,
		BatchID:         batchID,
		CourseID:        courseID,
		Type:            certType,
		CertificateCode: code,
		QRCodeURL:       qrURL,
		Status:          StatusActive,
		IssuedAt:        now,
		CreatedAt:       now,
		UpdatedAt:       now,
	}, nil
}

func (c *Certificate) Revoke(reason string) error {
	if c.Status == StatusRevoked {
		return ErrAlreadyRevoked
	}
	now := time.Now()
	c.Status = StatusRevoked
	c.RevokedAt = &now
	c.RevocationReason = reason
	c.UpdatedAt = now
	return nil
}

type WriteRepository interface {
	SaveTemplate(ctx context.Context, t *CertificateTemplate) error
	UpdateTemplate(ctx context.Context, t *CertificateTemplate) error
	Save(ctx context.Context, c *Certificate) error
	Revoke(ctx context.Context, id uuid.UUID, reason string, revokedAt time.Time) error
}

type ReadRepository interface {
	GetTemplateByID(ctx context.Context, id uuid.UUID) (*CertificateTemplate, error)
	ListTemplates(ctx context.Context) ([]*CertificateTemplate, error)
	GetByID(ctx context.Context, id uuid.UUID) (*Certificate, error)
	GetByCode(ctx context.Context, code string) (*Certificate, error)
	List(ctx context.Context, studentID, batchID *uuid.UUID, certType, status string, offset, limit int) ([]*Certificate, int, error)
}
