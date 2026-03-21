package update_invoice_status

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo accounting.InvoiceWriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo accounting.InvoiceWriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		writeRepo: writeRepo,
		eventBus:  eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateInvoiceStatusCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.writeRepo.UpdateStatus(ctx, c.ID, c.Status); err != nil {
		log.Error().Err(err).Str("invoice_id", c.ID.String()).Msg("failed to update invoice status")
		return err
	}

	log.Info().Str("invoice_id", c.ID.String()).Str("status", c.Status).Msg("invoice status updated successfully")
	return nil
}
