package get_agreement

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
)

var ErrInvalidQuery = errors.New("invalid query type")

type GetAgreementQuery struct {
	FranchiseeID uuid.UUID
}

type AgreementReadModel struct {
	ID                string  `json:"id"`
	FranchiseeID      string  `json:"franchisee_id"`
	BuyInFee          float64 `json:"buy_in_fee"`
	MonthlyRoyalty    float64 `json:"monthly_royalty"`
	RevenueRoyaltyPct float64 `json:"revenue_royalty_pct"`
	StartDate         string  `json:"start_date"`
	EndDate           string  `json:"end_date,omitempty"`
	Status            string  `json:"status"`
	CreatedAt         string  `json:"created_at"`
}

type Handler struct {
	readRepo franchise.ReadRepository
}

func NewHandler(readRepo franchise.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetAgreementQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	a, err := h.readRepo.GetAgreementByFranchiseeID(ctx, q.FranchiseeID)
	if err != nil {
		return nil, err
	}
	return &AgreementReadModel{
		ID:                a.ID.String(),
		FranchiseeID:      a.FranchiseeID.String(),
		BuyInFee:          a.BuyInFee,
		MonthlyRoyalty:    a.MonthlyRoyalty,
		RevenueRoyaltyPct: a.RevenueRoyaltyPct,
		StartDate:         a.StartDate,
		EndDate:           a.EndDate,
		Status:            a.Status,
		CreatedAt:         a.CreatedAt.Format("2006-01-02T15:04:05Z"),
	}, nil
}
