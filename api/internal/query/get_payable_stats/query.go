package get_payable_stats

import (
	"context"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
)

type GetPayableStatsQuery struct{}

func (q *GetPayableStatsQuery) QueryName() string { return "GetPayableStats" }

type PayableStatsRM struct {
	TotalPending   int   `json:"total_pending"`
	TotalApproved  int   `json:"total_approved"`
	TotalPaid      int   `json:"total_paid"`
	TotalCancelled int   `json:"total_cancelled"`
	AmountPending  int64 `json:"amount_pending"`
	AmountApproved int64 `json:"amount_approved"`
}

type Handler struct {
	repo payable.ReadRepository
}

func NewHandler(repo payable.ReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, q interface{}) (interface{}, error) {
	stats, err := h.repo.Stats(ctx)
	if err != nil {
		return nil, err
	}

	return &PayableStatsRM{
		TotalPending:   stats.TotalPending,
		TotalApproved:  stats.TotalApproved,
		TotalPaid:      stats.TotalPaid,
		TotalCancelled: stats.TotalCancelled,
		AmountPending:  stats.AmountPending,
		AmountApproved: stats.AmountApproved,
	}, nil
}
