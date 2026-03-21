package list_buildings

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
)

type BuildingListItem struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	Address     string    `json:"address"`
	Description string    `json:"description"`
	CreatedAt   int64     `json:"created_at"`
	UpdatedAt   int64     `json:"updated_at"`
}

type ListBuildingsResult struct {
	Data  []*BuildingListItem `json:"data"`
	Total int                 `json:"total"`
}

type Handler struct {
	buildingReadRepo building.ReadRepository
}

func NewHandler(buildingReadRepo building.ReadRepository) *Handler {
	return &Handler{buildingReadRepo: buildingReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListBuildingsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	limit := q.Limit
	if limit == 0 {
		limit = 20
	}

	buildings, total, err := h.buildingReadRepo.List(ctx, q.Offset, limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list buildings")
		return nil, err
	}

	items := make([]*BuildingListItem, 0, len(buildings))
	for _, b := range buildings {
		items = append(items, &BuildingListItem{
			ID:          b.ID,
			Name:        b.Name,
			Address:     b.Address,
			Description: b.Description,
			CreatedAt:   b.CreatedAt.Unix(),
			UpdatedAt:   b.UpdatedAt.Unix(),
		})
	}

	return &ListBuildingsResult{Data: items, Total: total}, nil
}
