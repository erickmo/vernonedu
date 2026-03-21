package cancel_invoice

import "github.com/google/uuid"

type CancelInvoiceCommand struct {
	InvoiceID   uuid.UUID `validate:"required"`
	Reason      string    `validate:"required"`
	CancelledBy uuid.UUID `validate:"required"`
}
