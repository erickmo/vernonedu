package list_investment_plans

import (
	"context"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/investment"
)

type ListInvestmentPlansQuery struct {
	Offset int
	Limit  int
	Status string
}

type InvestmentPlanModel struct {
	ID          string  `json:"id"`
	Title       string  `json:"title"`
	Category    string  `json:"category"`
	ProposedBy  string  `json:"proposed_by"`
	Amount      int64   `json:"amount"`
	ExpectedROI float64 `json:"expected_roi"`
	ActualSpend int64   `json:"actual_spend"`
	Status      string  `json:"status"`
	ApprovedBy  string  `json:"approved_by"`
	Notes       string  `json:"notes"`
}

type InvestmentStatsModel struct {
	TotalPlanned    int64   `json:"total_planned"`
	OngoingCount    int     `json:"ongoing_count"`
	OngoingAmount   int64   `json:"ongoing_amount"`
	CompletedCount  int     `json:"completed_count"`
	CompletedAmount int64   `json:"completed_amount"`
	AvgROI          float64 `json:"avg_roi"`
}

type ListInvestmentResult struct {
	Data   []*InvestmentPlanModel `json:"data"`
	Stats  *InvestmentStatsModel  `json:"stats"`
	Total  int                    `json:"total"`
	Offset int                    `json:"offset"`
	Limit  int                    `json:"limit"`
}

type Handler struct {
	readRepo investment.ReadRepository
}

func NewHandler(readRepo investment.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListInvestmentPlansQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	plans, total, err := h.readRepo.List(ctx, q.Offset, q.Limit, q.Status)
	if err != nil {
		return nil, err
	}
	stats, err := h.readRepo.Stats(ctx)
	if err != nil {
		return nil, err
	}

	models := make([]*InvestmentPlanModel, len(plans))
	for i, p := range plans {
		models[i] = &InvestmentPlanModel{
			ID:          p.ID.String(),
			Title:       p.Title,
			Category:    p.Category,
			ProposedBy:  p.ProposedBy,
			Amount:      p.Amount,
			ExpectedROI: p.ExpectedROI,
			ActualSpend: p.ActualSpend,
			Status:      p.Status,
			ApprovedBy:  p.ApprovedBy,
			Notes:       p.Notes,
		}
	}

	return &ListInvestmentResult{
		Data: models,
		Stats: &InvestmentStatsModel{
			TotalPlanned:    stats.TotalPlanned,
			OngoingCount:    stats.OngoingCount,
			OngoingAmount:   stats.OngoingAmount,
			CompletedCount:  stats.CompletedCount,
			CompletedAmount: stats.CompletedAmount,
			AvgROI:          stats.AvgROI,
		},
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
