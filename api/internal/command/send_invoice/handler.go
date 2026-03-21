package send_invoice

import (
	"context"
	"fmt"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	invoiceWriteRepo accounting.InvoiceWriteRepository
	invoiceReadRepo  accounting.InvoiceReadRepository
	eventBus         eventbus.EventBus
}

func NewHandler(
	invoiceWriteRepo accounting.InvoiceWriteRepository,
	invoiceReadRepo accounting.InvoiceReadRepository,
	eventBus eventbus.EventBus,
) *Handler {
	return &Handler{
		invoiceWriteRepo: invoiceWriteRepo,
		invoiceReadRepo:  invoiceReadRepo,
		eventBus:         eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*SendInvoiceCommand)
	if !ok {
		return ErrInvalidCommand
	}

	inv, err := h.invoiceReadRepo.GetByID(ctx, c.InvoiceID)
	if err != nil {
		return fmt.Errorf("invoice not found: %w", err)
	}

	if err := inv.Send(); err != nil {
		return err
	}

	if err := h.invoiceWriteRepo.Save(ctx, inv); err != nil {
		log.Error().Err(err).Str("invoice_id", c.InvoiceID.String()).Msg("failed to save sent invoice")
		return err
	}

	event := &accounting.InvoiceSentEvent{
		InvoiceID: inv.ID,
		Timestamp: time.Now().UnixMilli(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish InvoiceSent event")
	}

	log.Info().Str("invoice_id", inv.ID.String()).Msg("invoice sent")
	return nil
}
