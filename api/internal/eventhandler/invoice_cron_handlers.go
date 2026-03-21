package eventhandler

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
)

// MonthStartPayload represents the payload for the MonthStart cron event.
type MonthStartPayload struct {
	Month     int   `json:"month"`
	Year      int   `json:"year"`
	Timestamp int64 `json:"timestamp"`
}

// InvoiceCronHandler handles scheduled / cron-triggered invoice operations.
type InvoiceCronHandler struct {
	invoiceWriteRepo accounting.InvoiceWriteRepository
	invoiceReadRepo  accounting.InvoiceReadRepository
}

func NewInvoiceCronHandler(
	invoiceWriteRepo accounting.InvoiceWriteRepository,
	invoiceReadRepo accounting.InvoiceReadRepository,
) *InvoiceCronHandler {
	return &InvoiceCronHandler{
		invoiceWriteRepo: invoiceWriteRepo,
		invoiceReadRepo:  invoiceReadRepo,
	}
}

// OnMonthStart handles the MonthStart event for monthly batch invoices.
// TODO: implement full monthly invoice generation.
func (h *InvoiceCronHandler) OnMonthStart(ctx context.Context, data []byte) error {
	var payload MonthStartPayload
	if err := json.Unmarshal(data, &payload); err != nil {
		log.Error().Err(err).Msg("InvoiceCronHandler.OnMonthStart: failed to unmarshal payload")
		return err
	}

	log.Info().
		Int("month", payload.Month).
		Int("year", payload.Year).
		Msg("InvoiceCronHandler.OnMonthStart: monthly invoice generation triggered (TODO: full implementation)")

	return nil
}

// CheckOverdueInvoices marks unpaid past-due invoices as overdue and sends notifications.
func CheckOverdueInvoices(
	ctx context.Context,
	invoiceWriteRepo accounting.InvoiceWriteRepository,
	invoiceReadRepo accounting.InvoiceReadRepository,
	notifRepo notification.WriteRepository,
) error {
	asOf := time.Now()
	overdue, err := invoiceReadRepo.FindOverdueUnpaid(ctx, asOf)
	if err != nil {
		log.Error().Err(err).Msg("CheckOverdueInvoices: failed to find overdue invoices")
		return err
	}

	if len(overdue) == 0 {
		log.Info().Msg("CheckOverdueInvoices: no overdue invoices found")
		return nil
	}

	ids := make([]uuid.UUID, len(overdue))
	for i, inv := range overdue {
		ids[i] = inv.ID
	}

	if err := invoiceWriteRepo.MarkOverdue(ctx, ids); err != nil {
		log.Error().Err(err).Int("count", len(ids)).Msg("CheckOverdueInvoices: failed to bulk mark overdue")
		return err
	}

	// Notify students with overdue invoices
	if notifRepo != nil {
		for _, inv := range overdue {
			if inv.StudentID == nil {
				continue
			}
			n := notification.NewNotification(
				*inv.StudentID,
				notification.TypePayment,
				"Invoice Jatuh Tempo",
				"Invoice Anda "+inv.InvoiceNumber+" telah jatuh tempo. Harap segera melakukan pembayaran.",
				notification.ChannelInApp,
				map[string]interface{}{
					"invoice_id":     inv.ID.String(),
					"invoice_number": inv.InvoiceNumber,
					"amount":         inv.Amount,
				},
			)
			if err := notifRepo.Save(ctx, n); err != nil {
				log.Error().Err(err).
					Str("invoice_id", inv.ID.String()).
					Msg("CheckOverdueInvoices: failed to send overdue notification")
			}
		}
	}

	log.Info().Int("count", len(ids)).Msg("CheckOverdueInvoices: marked invoices as overdue")
	return nil
}
