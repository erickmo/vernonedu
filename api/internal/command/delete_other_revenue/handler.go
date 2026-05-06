package delete_other_revenue

import (
	"context"

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
	c, ok := cmd.(*DeleteOtherRevenueCommand)
	if !ok {
		return ErrInvalidCommand
	}
	return h.writeRepo.DeleteOtherRevenue(ctx, c.ID)
}
