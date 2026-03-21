package cancel_payable

import (
	"context"
	"time"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	readRepo  payable.ReadRepository
	writeRepo payable.WriteRepository
	bus       eventbus.EventBus
}

func NewHandler(readRepo payable.ReadRepository, writeRepo payable.WriteRepository, bus eventbus.EventBus) *Handler {
	return &Handler{readRepo: readRepo, writeRepo: writeRepo, bus: bus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CancelPayableCommand)
	if !ok || c == nil {
		return ErrInvalidCommand
	}

	p, err := h.readRepo.GetByID(ctx, c.ID)
	if err != nil {
		return err
	}

	if p.Status == payable.StatusPaid || p.Status == payable.StatusCancelled {
		return payable.ErrInvalidType
	}

	if err := h.writeRepo.UpdateStatus(ctx, c.ID, payable.StatusCancelled, nil, ""); err != nil {
		return err
	}

	_ = h.bus.Publish(ctx, &payable.PayableCancelledEvent{
		EventType: "PayableCancelled",
		PayableID: c.ID,
		Timestamp: time.Now().Unix(),
	})

	return nil
}
