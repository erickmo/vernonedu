package finance

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

// PaymentConfirmedPayload published when transaction confirmed and payment updated.
type PaymentConfirmedPayload struct {
	PaymentID    uuid.UUID       `json:"payment_id"`
	EnrollmentID uuid.UUID       `json:"enrollment_id"`
	Amount       decimal.Decimal `json:"amount"`
}

// PaymentTermOverduePayload published when a term passes due date unpaid.
type PaymentTermOverduePayload struct {
	TermID    uuid.UUID `json:"term_id"`
	PaymentID uuid.UUID `json:"payment_id"`
	DueDate   time.Time `json:"due_date"`
}

// InvoiceSentPayload published when invoice is sent.
type InvoiceSentPayload struct {
	InvoiceID uuid.UUID `json:"invoice_id"`
}

// InvoiceOverduePayload published when invoice passes due date.
type InvoiceOverduePayload struct {
	InvoiceID uuid.UUID `json:"invoice_id"`
}

// RegisterSubscriptions subscribes finance to cross-domain events.
func RegisterSubscriptions(bus events.Bus, svc *Service) {
	bus.Subscribe(events.EnrollmentConfirmed, func(_ context.Context, _ events.Event) error {
		return nil
	})
}
