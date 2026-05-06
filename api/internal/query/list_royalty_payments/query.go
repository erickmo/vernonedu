package list_royalty_payments

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
)

var ErrInvalidQuery = errors.New("invalid query type")

type ListRoyaltyPaymentsQuery struct {
	FranchiseeID uuid.UUID
	Period       string
}

type RoyaltyPaymentReadModel struct {
	ID             string  `json:"id"`
	Period         string  `json:"period"`
	GrossRevenue   float64 `json:"gross_revenue"`
	MonthlyRoyalty float64 `json:"monthly_royalty"`
	RevenueRoyalty float64 `json:"revenue_royalty"`
	TotalRoyalty   float64 `json:"total_royalty"`
	Status         string  `json:"status"`
	PaidAt         string  `json:"paid_at,omitempty"`
	CreatedAt      string  `json:"created_at"`
}

type ListResult struct {
	Data []*RoyaltyPaymentReadModel `json:"data"`
}

type Handler struct {
	readRepo franchise.ReadRepository
}

func NewHandler(readRepo franchise.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListRoyaltyPaymentsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	records, err := h.readRepo.ListRoyaltyPayments(ctx, q.FranchiseeID, q.Period)
	if err != nil {
		return nil, err
	}
	models := make([]*RoyaltyPaymentReadModel, len(records))
	for i, r := range records {
		m := &RoyaltyPaymentReadModel{
			ID:             r.ID.String(),
			Period:         r.Period,
			GrossRevenue:   r.GrossRevenue,
			MonthlyRoyalty: r.MonthlyRoyalty,
			RevenueRoyalty: r.RevenueRoyalty,
			TotalRoyalty:   r.TotalRoyalty,
			Status:         r.Status,
			CreatedAt:      r.CreatedAt.Format("2006-01-02T15:04:05Z"),
		}
		if r.PaidAt != nil {
			m.PaidAt = r.PaidAt.Format("2006-01-02T15:04:05Z")
		}
		models[i] = m
	}
	return &ListResult{Data: models}, nil
}
