package list_other_revenue

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
)

var ErrInvalidQuery = errors.New("invalid query type")

type ListOtherRevenueQuery struct {
	FranchiseeID uuid.UUID
	Period       string
}

type OtherRevenueReadModel struct {
	ID          string  `json:"id"`
	Label       string  `json:"label"`
	Amount      float64 `json:"amount"`
	RevenueDate string  `json:"revenue_date"`
	CreatedAt   string  `json:"created_at"`
}

type ListResult struct {
	Data []*OtherRevenueReadModel `json:"data"`
}

type Handler struct {
	readRepo franchise.ReadRepository
}

func NewHandler(readRepo franchise.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListOtherRevenueQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	revenues, err := h.readRepo.ListOtherRevenues(ctx, q.FranchiseeID, q.Period)
	if err != nil {
		return nil, err
	}
	models := make([]*OtherRevenueReadModel, len(revenues))
	for i, r := range revenues {
		models[i] = &OtherRevenueReadModel{
			ID:          r.ID.String(),
			Label:       r.Label,
			Amount:      r.Amount,
			RevenueDate: r.RevenueDate,
			CreatedAt:   r.CreatedAt.Format("2006-01-02T15:04:05Z"),
		}
	}
	return &ListResult{Data: models}, nil
}
