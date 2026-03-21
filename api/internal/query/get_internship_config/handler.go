package get_internship_config

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/internship"
)

// GetInternshipConfigQuery adalah query untuk mendapatkan konfigurasi magang berdasarkan course version ID.
type GetInternshipConfigQuery struct {
	CourseVersionID uuid.UUID
}

// InternshipConfigResult adalah read model yang dikembalikan oleh query ini.
type InternshipConfigResult struct {
	ID                 string `json:"id"`
	CourseVersionID    string `json:"course_version_id"`
	PartnerCompanyName string `json:"partner_company_name"`
	PartnerCompanyID   string `json:"partner_company_id"`
	PositionTitle      string `json:"position_title"`
	DurationWeeks      int    `json:"duration_weeks"`
	SupervisorName     string `json:"supervisor_name"`
	SupervisorContact  string `json:"supervisor_contact"`
	MOUDocumentURL     string `json:"mou_document_url"`
	IsCompanyProvided  bool   `json:"is_company_provided"`
	CreatedAt          int64  `json:"created_at"`
	UpdatedAt          int64  `json:"updated_at"`
}

// Handler menangani query GetInternshipConfig.
type Handler struct {
	readRepo internship.ReadRepository
}

// NewHandler membuat instance Handler baru untuk get_internship_config.
func NewHandler(readRepo internship.ReadRepository) *Handler {
	return &Handler{
		readRepo: readRepo,
	}
}

// Handle mengeksekusi query untuk mendapatkan konfigurasi magang dari sebuah course version.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetInternshipConfigQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	ic, err := h.readRepo.GetByVersionID(ctx, q.CourseVersionID)
	if err != nil {
		log.Error().Err(err).Str("course_version_id", q.CourseVersionID.String()).Msg("gagal mengambil konfigurasi magang")
		return nil, err
	}

	partnerCompanyID := ""
	if ic.PartnerCompanyID != nil {
		partnerCompanyID = ic.PartnerCompanyID.String()
	}

	return &InternshipConfigResult{
		ID:                 ic.ID.String(),
		CourseVersionID:    ic.CourseVersionID.String(),
		PartnerCompanyName: ic.PartnerCompanyName,
		PartnerCompanyID:   partnerCompanyID,
		PositionTitle:      ic.PositionTitle,
		DurationWeeks:      ic.DurationWeeks,
		SupervisorName:     ic.SupervisorName,
		SupervisorContact:  ic.SupervisorContact,
		MOUDocumentURL:     ic.MOUDocumentURL,
		IsCompanyProvided:  ic.IsCompanyProvided,
		CreatedAt:          ic.CreatedAt.Unix(),
		UpdatedAt:          ic.UpdatedAt.Unix(),
	}, nil
}
