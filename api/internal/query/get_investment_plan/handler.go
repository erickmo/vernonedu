package get_investment_plan

import (
	"context"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/investment"
)

type GetInvestmentPlanQuery struct {
	ID string
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

type Handler struct {
	readRepo investment.ReadRepository
}

func NewHandler(readRepo investment.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetInvestmentPlanQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	id, err := uuid.Parse(q.ID)
	if err != nil {
		return nil, ErrInvalidID
	}
	p, err := h.readRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	return &InvestmentPlanModel{
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
	}, nil
}
