package create_payable

import (
	"context"
	"time"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	repo payable.WriteRepository
	bus  eventbus.EventBus
}

func NewHandler(repo payable.WriteRepository, bus eventbus.EventBus) *Handler {
	return &Handler{repo: repo, bus: bus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreatePayableCommand)
	if !ok || c == nil {
		return ErrInvalidCommand
	}

	p, err := payable.NewPayable(
		c.Type,
		c.RecipientID,
		c.RecipientName,
		c.BatchID,
		c.Amount,
		payable.SourceManual,
		c.BranchID,
		c.Notes,
	)
	if err != nil {
		return err
	}

	if err := h.repo.Save(ctx, p); err != nil {
		return err
	}

	_ = h.bus.Publish(ctx, &payable.PayableCreatedEvent{
		EventType:   "PayableCreated",
		PayableID:   p.ID,
		PayableType: p.Type,
		RecipientID: p.RecipientID,
		Amount:      p.Amount,
		Timestamp:   time.Now().Unix(),
	})

	return nil
}
