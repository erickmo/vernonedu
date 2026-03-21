package send_invoice

import "github.com/google/uuid"

type SendInvoiceCommand struct {
	InvoiceID uuid.UUID `validate:"required"`
	SentBy    uuid.UUID `validate:"required"`
}
