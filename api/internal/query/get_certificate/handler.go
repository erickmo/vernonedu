package get_certificate

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/certificate"
)

type CertReadModel struct {
	ID               string `json:"id"`
	TemplateID       string `json:"template_id,omitempty"`
	StudentID        string `json:"student_id,omitempty"`
	BatchID          string `json:"batch_id,omitempty"`
	CourseID         string `json:"course_id,omitempty"`
	Type             string `json:"type"`
	CertificateCode  string `json:"certificate_code"`
	QRCodeURL        string `json:"qr_code_url"`
	Status           string `json:"status"`
	RevokedAt        string `json:"revoked_at,omitempty"`
	RevocationReason string `json:"revocation_reason,omitempty"`
	IssuedAt         string `json:"issued_at"`
}

type Handler struct {
	certReadRepo certificate.ReadRepository
}

func NewHandler(certReadRepo certificate.ReadRepository) *Handler {
	return &Handler{certReadRepo: certReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCertificateQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	c, err := h.certReadRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("certificate_id", q.ID.String()).Msg("failed to get certificate")
		return nil, err
	}

	return toCertReadModel(c), nil
}

func toCertReadModel(c *certificate.Certificate) *CertReadModel {
	m := &CertReadModel{
		ID:               c.ID.String(),
		Type:             string(c.Type),
		CertificateCode:  c.CertificateCode,
		QRCodeURL:        c.QRCodeURL,
		Status:           string(c.Status),
		RevocationReason: c.RevocationReason,
		IssuedAt:         c.IssuedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
	if c.TemplateID != nil {
		m.TemplateID = c.TemplateID.String()
	}
	if c.StudentID != nil {
		m.StudentID = c.StudentID.String()
	}
	if c.BatchID != nil {
		m.BatchID = c.BatchID.String()
	}
	if c.CourseID != nil {
		m.CourseID = c.CourseID.String()
	}
	if c.RevokedAt != nil {
		m.RevokedAt = c.RevokedAt.Format("2006-01-02T15:04:05Z07:00")
	}
	return m
}
