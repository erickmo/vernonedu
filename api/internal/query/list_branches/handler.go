package list_branches

import (
	"context"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/branch"
)

type ListBranchesQuery struct {
	Offset int
	Limit  int
}

type BranchReadModel struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	City         string `json:"city"`
	Address      string `json:"address"`
	Region       string `json:"region"`
	ContactName  string `json:"contact_name"`
	ContactPhone string `json:"contact_phone"`
	Status       string `json:"status"`
	PartnerName  string `json:"partner_name"`
	IsActive     bool   `json:"is_active"`
}

type ListBranchResult struct {
	Data   []*BranchReadModel `json:"data"`
	Total  int                `json:"total"`
	Offset int                `json:"offset"`
	Limit  int                `json:"limit"`
}

type Handler struct {
	readRepo branch.ReadRepository
}

func NewHandler(readRepo branch.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListBranchesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	branches, total, err := h.readRepo.List(ctx, q.Offset, q.Limit)
	if err != nil {
		return nil, err
	}

	models := make([]*BranchReadModel, len(branches))
	for i, b := range branches {
		models[i] = &BranchReadModel{
			ID:           b.ID.String(),
			Name:         b.Name,
			City:         b.City,
			Address:      b.Address,
			Region:       b.Region,
			ContactName:  b.ContactName,
			ContactPhone: b.ContactPhone,
			Status:       b.Status,
			PartnerName:  b.PartnerName,
			IsActive:     b.IsActive,
		}
	}
	return &ListBranchResult{
		Data:   models,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
