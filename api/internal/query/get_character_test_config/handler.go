package get_character_test_config

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/charactertest"
)

// GetCharacterTestConfigQuery adalah query untuk mendapatkan konfigurasi tes karakter berdasarkan course version ID.
type GetCharacterTestConfigQuery struct {
	CourseVersionID uuid.UUID
}

// CharacterTestConfigResult adalah read model yang dikembalikan oleh query ini.
type CharacterTestConfigResult struct {
	ID                 string  `json:"id"`
	CourseVersionID    string  `json:"course_version_id"`
	TestType           string  `json:"test_type"`
	TestProvider       string  `json:"test_provider"`
	PassingThreshold   float64 `json:"passing_threshold"`
	TalentpoolEligible bool    `json:"talentpool_eligible"`
	CreatedAt          int64   `json:"created_at"`
	UpdatedAt          int64   `json:"updated_at"`
}

// Handler menangani query GetCharacterTestConfig.
type Handler struct {
	readRepo charactertest.ReadRepository
}

// NewHandler membuat instance Handler baru untuk get_character_test_config.
func NewHandler(readRepo charactertest.ReadRepository) *Handler {
	return &Handler{
		readRepo: readRepo,
	}
}

// Handle mengeksekusi query untuk mendapatkan konfigurasi tes karakter dari sebuah course version.
func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCharacterTestConfigQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	ctc, err := h.readRepo.GetByVersionID(ctx, q.CourseVersionID)
	if err != nil {
		log.Error().Err(err).Str("course_version_id", q.CourseVersionID.String()).Msg("gagal mengambil konfigurasi tes karakter")
		return nil, err
	}

	return &CharacterTestConfigResult{
		ID:                 ctc.ID.String(),
		CourseVersionID:    ctc.CourseVersionID.String(),
		TestType:           ctc.TestType,
		TestProvider:       ctc.TestProvider,
		PassingThreshold:   ctc.PassingThreshold,
		TalentpoolEligible: ctc.TalentpoolEligible,
		CreatedAt:          ctc.CreatedAt.Unix(),
		UpdatedAt:          ctc.UpdatedAt.Unix(),
	}, nil
}
