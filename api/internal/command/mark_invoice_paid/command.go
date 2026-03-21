package mark_invoice_paid

import (
	"time"

	"github.com/google/uuid"
)

type MarkInvoicePaidCommand struct {
	InvoiceID    uuid.UUID `validate:"required"`
	PaidAt       time.Time `validate:"required"`
	PaidAmount   float64   `validate:"required,gt=0"`
	PaidBy       uuid.UUID `validate:"required"`
	PaymentProof string
	AccountCode  string `validate:"required"` // 1101=kas or 1102=bank
}
