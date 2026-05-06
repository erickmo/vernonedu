package create_agreement

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo franchise.WriteRepository
}

func NewHandler(writeRepo franchise.WriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateAgreementCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	status := c.Status
	if status == "" {
		status = "active"
	}
	a := &franchise.FranchiseAgreement{
		ID:                uuid.New(),
		FranchiseeID:      c.FranchiseeID,
		BuyInFee:          c.BuyInFee,
		MonthlyRoyalty:    c.MonthlyRoyalty,
		RevenueRoyaltyPct: c.RevenueRoyaltyPct,
		StartDate:         c.StartDate,
		EndDate:           c.EndDate,
		Status:            status,
		CreatedAt:         now,
		UpdatedAt:         now,
	}
	return h.writeRepo.SaveAgreement(ctx, a)
}
