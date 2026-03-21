package get_building

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
)

type BuildingReadModel struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Address     string    `json:"address"`
	Description string    `json:"description"`
	CreatedAt   int64     `json:"created_at"`
	UpdatedAt   int64     `json:"updated_at"`
}

type Handler struct {
	buildingReadRepo building.ReadRepository
}

func NewHandler(buildingReadRepo building.ReadRepository) *Handler {
	return &Handler{buildingReadRepo: buildingReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetBuildingQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	b, err := h.buildingReadRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("building_id", q.ID.String()).Msg("failed to get building")
		return nil, err
	}

	return &BuildingReadModel{
		ID:          b.ID,
		Name:        b.Name,
		Address:     b.Address,
		Description: b.Description,
		CreatedAt:   b.CreatedAt.Unix(),
		UpdatedAt:   b.UpdatedAt.Unix(),
	}, nil
}
