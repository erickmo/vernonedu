package list_payables

import (
	"context"
	"time"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
)

type ListPayablesQuery struct {
	Type        string
	Status      string
	BatchID     string
	RecipientID string
	DateFrom    string
	DateTo      string
	Offset      int
	Limit       int
}

func (q *ListPayablesQuery) QueryName() string { return "ListPayables" }

type PayableRM struct {
	ID                    string
	Type                  string
	RecipientID           string
	RecipientName         string
	BatchID               *string
	Amount                int64
	CalculationBasis      string
	CalculationPercentage float64
	Status                string
	Source                string
	PaidAt                *time.Time
	PaymentProof          string
	BranchID              *string
	Notes                 string
	CreatedAt             time.Time
	UpdatedAt             time.Time
}

type ListPayablesResult struct {
	Items []*PayableRM
	Total int
}

type Handler struct {
	repo payable.ReadRepository
}

func NewHandler(repo payable.ReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, q interface{}) (interface{}, error) {
	qry, ok := q.(*ListPayablesQuery)
	if !ok || qry == nil {
		return &ListPayablesResult{Items: []*PayableRM{}}, nil
	}

	limit := qry.Limit
	if limit <= 0 {
		limit = 20
	}

	items, total, err := h.repo.List(ctx,
		qry.Type, qry.Status, qry.BatchID, qry.RecipientID,
		qry.DateFrom, qry.DateTo,
		qry.Offset, limit,
	)
	if err != nil {
		return nil, err
	}

	rms := make([]*PayableRM, 0, len(items))
	for _, p := range items {
		rms = append(rms, toRM(p))
	}

	return &ListPayablesResult{Items: rms, Total: total}, nil
}

func toRM(p *payable.Payable) *PayableRM {
	rm := &PayableRM{
		ID:                    p.ID.String(),
		Type:                  p.Type,
		RecipientID:           p.RecipientID.String(),
		RecipientName:         p.RecipientName,
		Amount:                p.Amount,
		CalculationBasis:      p.CalculationBasis,
		CalculationPercentage: p.CalculationPercentage,
		Status:                p.Status,
		Source:                p.Source,
		PaidAt:                p.PaidAt,
		PaymentProof:          p.PaymentProof,
		Notes:                 p.Notes,
		CreatedAt:             p.CreatedAt,
		UpdatedAt:             p.UpdatedAt,
	}
	if p.BatchID != nil {
		s := p.BatchID.String()
		rm.BatchID = &s
	}
	if p.BranchID != nil {
		s := p.BranchID.String()
		rm.BranchID = &s
	}
	return rm
}
