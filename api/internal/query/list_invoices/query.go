package list_invoices

import (
	"time"

	"github.com/google/uuid"
)

type ListInvoicesQuery struct {
	Offset        int
	Limit         int
	Month         int
	Year          int
	Status        string
	BatchID       *uuid.UUID
	StudentID     *uuid.UUID
	PaymentMethod string
	DateFrom      *time.Time
	DateTo        *time.Time
}
