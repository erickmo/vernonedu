package list_certificates

import (
	"context"

	"github.com/google/uuid"
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

type Meta struct {
	Total  int `json:"total"`
	Offset int `json:"offset"`
	Limit  int `json:"limit"`
}

type ListResult struct {
	Data []*CertReadModel `json:"data"`
	Meta Meta             `json:"meta"`
}

type Handler struct {
	certReadRepo certificate.ReadRepository
}

func NewHandler(certReadRepo certificate.ReadRepository) *Handler {
	return &Handler{certReadRepo: certReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCertificatesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	var studentID *uuid.UUID
	if q.StudentID != "" {
		id, err := uuid.Parse(q.StudentID)
		if err == nil {
			studentID = &id
		}
	}

	var batchID *uuid.UUID
	if q.BatchID != "" {
		id, err := uuid.Parse(q.BatchID)
		if err == nil {
			batchID = &id
		}
	}

	limit := q.Limit
	if limit == 0 {
		limit = 10
	}

	certs, total, err := h.certReadRepo.List(ctx, studentID, batchID, q.Type, q.Status, q.Offset, limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list certificates")
		return nil, err
	}

	readModels := make([]*CertReadModel, len(certs))
	for i, c := range certs {
		readModels[i] = toCertReadModel(c)
	}

	return &ListResult{
		Data: readModels,
		Meta: Meta{
			Total:  total,
			Offset: q.Offset,
			Limit:  limit,
		},
	}, nil
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
