package get_payable

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
)

type GetPayableQuery struct {
	ID uuid.UUID
}

func (q *GetPayableQuery) QueryName() string { return "GetPayable" }

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

type Handler struct {
	repo payable.ReadRepository
}

func NewHandler(repo payable.ReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, q interface{}) (interface{}, error) {
	qry, ok := q.(*GetPayableQuery)
	if !ok || qry == nil {
		return nil, payable.ErrPayableNotFound
	}

	p, err := h.repo.GetByID(ctx, qry.ID)
	if err != nil {
		return nil, err
	}

	return toRM(p), nil
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
