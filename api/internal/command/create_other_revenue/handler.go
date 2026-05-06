package create_other_revenue

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
	c, ok := cmd.(*CreateOtherRevenueCommand)
	if !ok {
		return ErrInvalidCommand
	}
	now := time.Now()
	r := &franchise.BranchOtherRevenue{
		ID:           uuid.New(),
		FranchiseeID: c.FranchiseeID,
		Label:        c.Label,
		Amount:       c.Amount,
		RevenueDate:  c.RevenueDate,
		AddedBy:      c.AddedBy,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	return h.writeRepo.SaveOtherRevenue(ctx, r)
}
