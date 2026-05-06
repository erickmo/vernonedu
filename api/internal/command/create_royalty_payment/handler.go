package create_royalty_payment

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/franchise"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo franchise.WriteRepository
	readRepo  franchise.ReadRepository
}

func NewHandler(writeRepo franchise.WriteRepository, readRepo franchise.ReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateRoyaltyPaymentCommand)
	if !ok {
		return ErrInvalidCommand
	}
	agreement, err := h.readRepo.GetAgreementByFranchiseeID(ctx, c.FranchiseeID)
	if err != nil {
		return err
	}
	revenueRoyalty := c.GrossRevenue * agreement.RevenueRoyaltyPct / 100
	totalRoyalty := agreement.MonthlyRoyalty + revenueRoyalty
	now := time.Now()
	r := &franchise.RoyaltyPaymentRecord{
		ID:                   uuid.New(),
		FranchiseAgreementID: agreement.ID,
		Period:               c.Period,
		GrossRevenue:         c.GrossRevenue,
		MonthlyRoyalty:       agreement.MonthlyRoyalty,
		RevenueRoyalty:       revenueRoyalty,
		TotalRoyalty:         totalRoyalty,
		Status:               "unpaid",
		RecordedBy:           c.RecordedBy,
		CreatedAt:            now,
		UpdatedAt:            now,
	}
	return h.writeRepo.SaveRoyaltyPayment(ctx, r)
}
