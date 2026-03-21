package update_invoice_status

import "github.com/google/uuid"

type UpdateInvoiceStatusCommand struct {
	ID     uuid.UUID `validate:"required"`
	Status string    `validate:"required"`
}
