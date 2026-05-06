package get_building

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
)

type PartnerSummary struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type BuildingReadModel struct {
	ID          uuid.UUID       `json:"id"`
	Name        string          `json:"name"`
	Address     string          `json:"address"`
	Description string          `json:"description"`
	Ownership   string          `json:"ownership"`
	Partner     *PartnerSummary `json:"partner,omitempty"`
	CreatedAt   int64           `json:"created_at"`
	UpdatedAt   int64           `json:"updated_at"`
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

	bwp, err := h.buildingReadRepo.GetByIDWithPartner(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("building_id", q.ID.String()).Msg("failed to get building")
		return nil, err
	}

	rm := &BuildingReadModel{
		ID:          bwp.ID,
		Name:        bwp.Name,
		Address:     bwp.Address,
		Description: bwp.Description,
		Ownership:   bwp.Ownership,
		CreatedAt:   bwp.CreatedAt.Unix(),
		UpdatedAt:   bwp.UpdatedAt.Unix(),
	}
	if bwp.Partner != nil {
		rm.Partner = &PartnerSummary{
			ID:   bwp.Partner.ID.String(),
			Name: bwp.Partner.Name,
		}
	}
	return rm, nil
}
