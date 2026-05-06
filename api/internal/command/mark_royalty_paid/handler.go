package mark_royalty_paid

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
	c, ok := cmd.(*MarkRoyaltyPaidCommand)
	if !ok {
		return ErrInvalidCommand
	}
	record, err := h.readRepo.GetRoyaltyPaymentByID(ctx, c.RecordID)
	if err != nil {
		return err
	}
	if record.Status == "paid" {
		return ErrAlreadyPaid
	}
	return h.writeRepo.MarkRoyaltyPaid(ctx, c.RecordID, time.Now())
}
