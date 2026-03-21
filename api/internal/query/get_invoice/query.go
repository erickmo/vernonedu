package get_invoice

import "github.com/google/uuid"

type GetInvoiceQuery struct {
	InvoiceID uuid.UUID
}
