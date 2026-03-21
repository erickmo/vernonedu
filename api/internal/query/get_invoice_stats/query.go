package get_invoice_stats

import "github.com/google/uuid"

type GetInvoiceStatsQuery struct {
	BranchID *uuid.UUID
	Month    int
	Year     int
}
