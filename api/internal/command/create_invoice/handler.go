package create_invoice

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
	txWriteRepo      accounting.TransactionWriteRepository
	eventBus         eventbus.EventBus
}

func NewHandler(
	invoiceWriteRepo accounting.InvoiceWriteRepository,
	txWriteRepo accounting.TransactionWriteRepository,
	eventBus eventbus.EventBus,
) *Handler {
	return &Handler{
		invoiceWriteRepo: invoiceWriteRepo,
		txWriteRepo:      txWriteRepo,
		eventBus:         eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateInvoiceCommand)
	if !ok {
		return ErrInvalidCommand
	}

	now := time.Now()
	seq := int(now.UnixNano() % 9999)
	if seq <= 0 {
		seq = 1
	}
	invNumber := accounting.GenerateInvoiceNumber(seq)

	dueDate := c.DueDate
	params := accounting.NewInvoiceParams{
		StudentID:     c.StudentID,
		EnrollmentID:  c.EnrollmentID,
		CourseBatchID: &c.BatchID,
		StudentName:   c.StudentName,
		BatchName:     c.BatchName,
		ClientName:    c.ClientName,
		PaymentMethod: c.PaymentMethod,
		Amount:        float64(c.Amount),
		DueDate:       &dueDate,
		Notes:         c.Notes,
		Source:        accounting.SourceManual,
		BranchID:      c.BranchID,
		InvoiceNumber: invNumber,
	}

	inv, err := accounting.NewInvoice(params)
	if err != nil {
		return fmt.Errorf("failed to build invoice: %w", err)
	}

	if err := h.invoiceWriteRepo.Save(ctx, inv); err != nil {
		log.Error().Err(err).Msg("failed to save invoice")
		return err
	}

	// Journal entry: debit Piutang Usaha (1103), credit Pendapatan Kursus (4001)
	createdBy := c.CreatedBy
	tx := &accounting.Transaction{
		ID:                uuid.New(),
		Description:       fmt.Sprintf("Invoice %s - %s", inv.InvoiceNumber, inv.BatchName),
		TransactionType:   "income",
		Amount:            inv.Amount,
		DebitAccountCode:  "1103",
		CreditAccountCode: "4001",
		Category:          "course_revenue",
		RelatedEntityType: "invoice",
		RelatedEntityID:   &inv.ID,
		TransactionDate:   now,
		Status:            "completed",
		CreatedBy:         &createdBy,
		CreatedAt:         now,
		UpdatedAt:         now,
	}
	if err := h.txWriteRepo.Create(ctx, tx); err != nil {
		log.Error().Err(err).Str("invoice_id", inv.ID.String()).Msg("failed to create journal entry for invoice")
		// Non-fatal: invoice was already saved
	}

	event := &accounting.InvoiceCreatedEvent{
		InvoiceID:     inv.ID,
		InvoiceNumber: inv.InvoiceNumber,
		StudentID:     inv.StudentID,
		EnrollmentID:  inv.EnrollmentID,
		CourseBatchID: inv.CourseBatchID,
		Amount:        inv.Amount,
		Source:        inv.Source,
		Timestamp:     now.UnixMilli(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish InvoiceCreated event")
	}

	log.Info().Str("invoice_id", inv.ID.String()).Str("invoice_number", inv.InvoiceNumber).Msg("invoice created successfully")
	return nil
}
