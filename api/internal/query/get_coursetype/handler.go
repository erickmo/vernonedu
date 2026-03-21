package get_coursetype

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursetype"
)

// ErrInvalidQuery dikembalikan ketika tipe query tidak sesuai.
var ErrInvalidQuery = errors.New("invalid query type")

// GetCourseTypeQuery adalah query untuk mengambil satu CourseType berdasarkan ID.
type GetCourseTypeQuery struct {
	CourseTypeID uuid.UUID
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
	NormalPrice            int64                               `json:"normal_price"`
	MinPrice               int64                               `json:"min_price"`
	MinParticipants        int                                 `json:"min_participants"`
	MaxParticipants        int                                 `json:"max_participants"`
	CreatedAt              int64                               `json:"created_at"`
	UpdatedAt              int64                               `json:"updated_at"`
}

// Handler menangani GetCourseTypeQuery.
type Handler struct {
	readRepo coursetype.ReadRepository
}

// NewHandler membuat instance baru Handler.
func NewHandler(readRepo coursetype.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

// Handle mengeksekusi query untuk mengambil satu CourseType.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCourseTypeQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	ct, err := h.readRepo.GetByID(ctx, q.CourseTypeID)
	if err != nil {
		log.Error().Err(err).Str("course_type_id", q.CourseTypeID.String()).Msg("failed to get course type")
		return nil, err
	}

	return toReadModel(ct), nil
}

// toReadModel mengonversi domain entity ke read model.
func toReadModel(ct *coursetype.CourseType) *CourseTypeReadModel {
	return &CourseTypeReadModel{
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
		NormalPrice:            ct.NormalPrice,
		MinPrice:               ct.MinPrice,
		MinParticipants:        ct.MinParticipants,
		MaxParticipants:        ct.MaxParticipants,
		CreatedAt:              ct.CreatedAt.Unix(),
		UpdatedAt:              ct.UpdatedAt.Unix(),
	}
}
