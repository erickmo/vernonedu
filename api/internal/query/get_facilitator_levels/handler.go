package get_facilitator_levels

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

// FacilitatorLevelReadModel is the response shape for a facilitator level.
type FacilitatorLevelReadModel struct {
	ID            uuid.UUID `json:"id"`
	Level         int       `json:"level"`
	Name          string    `json:"name"`
	FeePerSession int64     `json:"fee_per_session"`
	UpdatedAt     int64     `json:"updated_at"`
}

type Handler struct {
	readRepo settings.FacilitatorLevelReadRepository
}

func NewHandler(readRepo settings.FacilitatorLevelReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	_, ok := query.(*GetFacilitatorLevelsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	levels, err := h.readRepo.List(ctx)
	if err != nil {
		log.Error().Err(err).Msg("failed to get facilitator levels")
		return nil, err
	}

	readModels := make([]*FacilitatorLevelReadModel, len(levels))
	for i, l := range levels {
		readModels[i] = &FacilitatorLevelReadModel{
			ID:            l.ID,
			Level:         l.Level,
			Name:          l.Name,
			FeePerSession: l.FeePerSession,
			UpdatedAt:     l.UpdatedAt.Unix(),
		}
	}

	return readModels, nil
}
