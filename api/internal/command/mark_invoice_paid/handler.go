package mark_invoice_paid

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	invoiceWriteRepo accounting.InvoiceWriteRepository
	invoiceReadRepo  accounting.InvoiceReadRepository
	txWriteRepo      accounting.TransactionWriteRepository
	eventBus         eventbus.EventBus
}

func NewHandler(
	invoiceWriteRepo accounting.InvoiceWriteRepository,
	invoiceReadRepo accounting.InvoiceReadRepository,
	txWriteRepo accounting.TransactionWriteRepository,
	eventBus eventbus.EventBus,
) *Handler {
	return &Handler{
		invoiceWriteRepo: invoiceWriteRepo,
		invoiceReadRepo:  invoiceReadRepo,
		txWriteRepo:      txWriteRepo,
		eventBus:         eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*MarkInvoicePaidCommand)
	if !ok {
		return ErrInvalidCommand
	}

	inv, err := h.invoiceReadRepo.GetByID(ctx, c.InvoiceID)
	if err != nil {
		return fmt.Errorf("invoice not found: %w", err)
	}

	if err := inv.MarkPaid(c.PaidAt, c.PaidAmount, c.PaidBy, c.PaymentProof); err != nil {
		return err
	}

	if err := h.invoiceWriteRepo.Save(ctx, inv); err != nil {
		log.Error().Err(err).Str("invoice_id", c.InvoiceID.String()).Msg("failed to save paid invoice")
		return err
	}

	// Journal entry: debit Cash/Bank (1101 or 1102), credit Piutang Usaha (1103)
	now := time.Now()
	accountCode := c.AccountCode
	if accountCode == "" {
		accountCode = "1101"
	}
	paidBy := c.PaidBy
	tx := &accounting.Transaction{
		ID:                uuid.New(),
		Description:       fmt.Sprintf("Payment received — Invoice %s", inv.InvoiceNumber),
		TransactionType:   "income",
		Amount:            c.PaidAmount,
		DebitAccountCode:  accountCode,
		CreditAccountCode: "1103",
		Category:          "invoice_payment",
		RelatedEntityType: "invoice",
		RelatedEntityID:   &inv.ID,
		TransactionDate:   c.PaidAt,
		Status:            "completed",
		CreatedBy:         &paidBy,
		CreatedAt:         now,
		UpdatedAt:         now,
	}
	if err := h.txWriteRepo.Create(ctx, tx); err != nil {
		log.Error().Err(err).Str("invoice_id", c.InvoiceID.String()).Msg("failed to create payment journal entry")
	}

	event := &accounting.InvoicePaidEvent{
		InvoiceID:  inv.ID,
		PaidAt:     c.PaidAt.UnixMilli(),
		PaidAmount: c.PaidAmount,
		PaidBy:     c.PaidBy,
		AccountCode: accountCode,
		Timestamp:  now.UnixMilli(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish InvoicePaid event")
	}

	log.Info().Str("invoice_id", inv.ID.String()).Msg("invoice marked as paid")
	return nil
}
