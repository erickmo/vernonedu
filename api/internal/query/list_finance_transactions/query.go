package list_finance_transactions

import (
	"time"

	"github.com/google/uuid"
)

type ListFinanceTransactionsQuery struct {
	Offset    int
	Limit     int
	Source    string
	AccountID *uuid.UUID
	BranchID  *uuid.UUID
	DateFrom  *time.Time
	DateTo    *time.Time
}
