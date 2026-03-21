package list_partner_groups

import (
	"context"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/partner"
)

// ListPartnerGroupsQuery has no filters — returns all groups.
type ListPartnerGroupsQuery struct{}

type PartnerGroupReadModel struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type Handler struct {
	readRepo partner.ReadRepository
}

func NewHandler(readRepo partner.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	_, ok := query.(*ListPartnerGroupsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	groups, err := h.readRepo.ListGroups(ctx)
	if err != nil {
		return nil, err
	}
	models := make([]PartnerGroupReadModel, len(groups))
	for i, g := range groups {
		models[i] = PartnerGroupReadModel{
			ID:          g.ID.String(),
			Name:        g.Name,
			Description: g.Description,
		}
	}
	return models, nil
}
