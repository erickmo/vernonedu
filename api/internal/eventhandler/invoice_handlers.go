package eventhandler

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/coursebatch"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/enrollment"
)

// EnrollmentCreatedPayload mirrors the EnrollmentCreated event fields.
type EnrollmentCreatedPayload struct {
	EnrollmentID  uuid.UUID `json:"enrollment_id"`
	StudentID     uuid.UUID `json:"student_id"`
	CourseBatchID uuid.UUID `json:"course_batch_id"`
	Timestamp     int64     `json:"timestamp"`
}

// InvoiceEventHandler handles invoice-related domain events triggered by enrollment and attendance.
type InvoiceEventHandler struct {
	invoiceWriteRepo accounting.InvoiceWriteRepository
	batchReadRepo    coursebatch.ReadRepository
	txWriteRepo      accounting.TransactionWriteRepository
	enrollReadRepo   enrollment.ReadRepository
}

func NewInvoiceEventHandler(
	invoiceWriteRepo accounting.InvoiceWriteRepository,
	batchReadRepo coursebatch.ReadRepository,
	txWriteRepo accounting.TransactionWriteRepository,
	enrollReadRepo enrollment.ReadRepository,
) *InvoiceEventHandler {
	return &InvoiceEventHandler{
		invoiceWriteRepo: invoiceWriteRepo,
		batchReadRepo:    batchReadRepo,
		txWriteRepo:      txWriteRepo,
		enrollReadRepo:   enrollReadRepo,
	}
}

// OnEnrollmentCreated handles EnrollmentCreated events and auto-creates invoices based on payment method.
func (h *InvoiceEventHandler) OnEnrollmentCreated(ctx context.Context, data []byte) error {
	var payload EnrollmentCreatedPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("InvoiceHandler.OnEnrollmentCreated: failed to unmarshal payload")
		return err
	}

	batch, err := h.batchReadRepo.GetByID(ctx, payload.CourseBatchID)
	if err != nil {
		log.Error().Err(err).Str("batch_id", payload.CourseBatchID.String()).Msg("InvoiceHandler.OnEnrollmentCreated: failed to get batch")
		return err
	}

	enroll, err := h.enrollReadRepo.GetByID(ctx, payload.EnrollmentID)
	if err != nil {
		log.Error().Err(err).Str("enrollment_id", payload.EnrollmentID.String()).Msg("InvoiceHandler.OnEnrollmentCreated: failed to get enrollment")
		return err
	}

	switch batch.PaymentMethod {
	case coursebatch.PaymentMethodUpfront, coursebatch.PaymentMethodScheduled, coursebatch.PaymentMethodBatchLump:
		dueDate := batch.StartDate.AddDate(0, 0, -7)
		if err := h.createAutoInvoice(ctx, batch, enroll, payload.StudentID, dueDate); err != nil {
			log.Error().Err(err).
				Str("batch_id", batch.ID.String()).
				Str("enrollment_id", enroll.ID.String()).
				Msgf("InvoiceHandler.OnEnrollmentCreated: failed to create invoice for payment method %s", batch.PaymentMethod)
			return err
		}
	case coursebatch.PaymentMethodMonthly:
		// Created at month start via cron — skip here
		log.Info().Str("enrollment_id", enroll.ID.String()).Msg("InvoiceHandler.OnEnrollmentCreated: monthly payment — invoice deferred to month-start cron")
	case coursebatch.PaymentMethodPerSession:
		// Created after each session — skip here
		log.Info().Str("enrollment_id", enroll.ID.String()).Msg("InvoiceHandler.OnEnrollmentCreated: per-session payment — invoice deferred to session completion")
	default:
		log.Warn().Str("payment_method", batch.PaymentMethod).Msg("InvoiceHandler.OnEnrollmentCreated: unrecognized payment method")
	}

	return nil
}

func (h *InvoiceEventHandler) createAutoInvoice(
	ctx context.Context,
	batch *coursebatch.CourseBatch,
	enroll *enrollment.Enrollment,
	studentID uuid.UUID,
	dueDate time.Time,
) error {
	now := time.Now()
	seq := int(now.UnixNano() % 9999)
	if seq <= 0 {
		seq = 1
	}
	invNumber := accounting.GenerateInvoiceNumber(seq)

	enrollID := enroll.ID
	sID := studentID
	params := accounting.NewInvoiceParams{
		StudentID:     &sID,
		EnrollmentID:  &enrollID,
		CourseBatchID: &batch.ID,
		BatchName:     batch.Name,
		PaymentMethod: batch.PaymentMethod,
		Amount:        float64(batch.Price),
		DueDate:       &dueDate,
		Source:        accounting.SourceAuto,
		InvoiceNumber: invNumber,
	}

	inv, err := accounting.NewInvoice(params)
	if err != nil {
		return fmt.Errorf("failed to build auto invoice: %w", err)
	}

	if err := h.invoiceWriteRepo.Save(ctx, inv); err != nil {
		return fmt.Errorf("failed to save auto invoice: %w", err)
	}

	// Journal entry: debit Piutang Usaha (1103), credit Pendapatan Kursus (4001)
	tx := &accounting.Transaction{
		ID:                uuid.New(),
		Description:       fmt.Sprintf("Auto Invoice %s — %s", inv.InvoiceNumber, batch.Name),
		TransactionType:   "income",
		Amount:            inv.Amount,
		DebitAccountCode:  "1103",
		CreditAccountCode: "4001",
		Category:          "course_revenue",
		RelatedEntityType: "invoice",
		RelatedEntityID:   &inv.ID,
		TransactionDate:   now,
		Status:            "completed",
		CreatedAt:         now,
		UpdatedAt:         now,
	}
	if err := h.txWriteRepo.Create(ctx, tx); err != nil {
		log.Error().Err(err).Str("invoice_id", inv.ID.String()).Msg("InvoiceHandler: failed to create journal entry for auto invoice")
		// Non-fatal
	}

	log.Info().
		Str("invoice_id", inv.ID.String()).
		Str("invoice_number", inv.InvoiceNumber).
		Str("batch_id", batch.ID.String()).
		Msg("InvoiceHandler.OnEnrollmentCreated: auto invoice created")
	return nil
}
