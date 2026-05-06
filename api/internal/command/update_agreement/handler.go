package update_agreement

import (
	"context"
	"time"

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
	c, ok := cmd.(*UpdateAgreementCommand)
	if !ok {
		return ErrInvalidCommand
	}
	a, err := h.readRepo.GetAgreementByID(ctx, c.ID)
	if err != nil {
		return err
	}
	a.BuyInFee = c.BuyInFee
	a.MonthlyRoyalty = c.MonthlyRoyalty
	a.RevenueRoyaltyPct = c.RevenueRoyaltyPct
	a.StartDate = c.StartDate
	a.EndDate = c.EndDate
	a.Status = c.Status
	a.UpdatedAt = time.Now()
	return h.writeRepo.UpdateAgreement(ctx, a)
}
