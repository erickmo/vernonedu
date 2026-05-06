package update_other_revenue

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
	c, ok := cmd.(*UpdateOtherRevenueCommand)
	if !ok {
		return ErrInvalidCommand
	}
	r, err := h.readRepo.GetOtherRevenueByID(ctx, c.ID)
	if err != nil {
		return err
	}
	r.Label = c.Label
	r.Amount = c.Amount
	r.RevenueDate = c.RevenueDate
	r.UpdatedAt = time.Now()
	return h.writeRepo.UpdateOtherRevenue(ctx, r)
}
