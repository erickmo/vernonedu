package list_coursetype

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursetype"
)

// ErrInvalidQuery dikembalikan ketika tipe query tidak sesuai.
var ErrInvalidQuery = errors.New("invalid query type")

// ListCourseTypeQuery adalah query untuk mengambil semua CourseType dari satu MasterCourse.
type ListCourseTypeQuery struct {
	MasterCourseID uuid.UUID
}

// CourseTypeReadModel adalah model baca untuk CourseType.
type CourseTypeReadModel struct {
	ID                     string                              `json:"id"`
	MasterCourseID         string                              `json:"master_course_id"`
	TypeName               string                              `json:"type_name"`
	IsActive               bool                                `json:"is_active"`
	PriceType              string                              `json:"price_type"`
	PriceMin               *int64                              `json:"price_min"`
	PriceMax               *int64                              `json:"price_max"`
	PriceCurrency          string                              `json:"price_currency"`
	PriceNotes             string                              `json:"price_notes"`
	TargetAudience         string                              `json:"target_audience"`
	ExtraDocs              []string                            `json:"extra_docs"`
	CertificationType      string                              `json:"certification_type"`
	ComponentFailureConfig *coursetype.ComponentFailureConfig  `json:"component_failure_config"`
	CreatedAt              int64                               `json:"created_at"`
	UpdatedAt              int64                               `json:"updated_at"`
}

// Handler menangani ListCourseTypeQuery.
type Handler struct {
	readRepo coursetype.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo coursetype.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query untuk mengambil daftar CourseType.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListCourseTypeQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	types, err := h.readRepo.ListByMasterCourse(ctx, q.MasterCourseID)
	if err != nil {
		log.Error().Err(err).Str("master_course_id", q.MasterCourseID.String()).Msg("failed to list course types")
		return nil, err
	}

	readModels := make([]*CourseTypeReadModel, len(types))
	for i, ct := range types {
		readModels[i] = &CourseTypeReadModel{
			ID:                     ct.ID.String(),
			MasterCourseID:         ct.MasterCourseID.String(),
			TypeName:               ct.TypeName,
			IsActive:               ct.IsActive,
			PriceType:              ct.PriceType,
			PriceMin:               ct.PriceMin,
			PriceMax:               ct.PriceMax,
			PriceCurrency:          ct.PriceCurrency,
			PriceNotes:             ct.PriceNotes,
			TargetAudience:         ct.TargetAudience,
			ExtraDocs:              ct.ExtraDocs,
			CertificationType:      ct.CertificationType,
			ComponentFailureConfig: ct.ComponentFailureConfig,
			CreatedAt:              ct.CreatedAt.Unix(),
			UpdatedAt:              ct.UpdatedAt.Unix(),
		}
	}

	return readModels, nil
}
