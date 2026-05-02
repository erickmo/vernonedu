package get_balance_by_account

import (
	"time"

	"github.com/google/uuid"
)

type GetBalanceByAccountQuery struct {
	CoaCode  string
	BranchID *uuid.UUID
	DateTo   *time.Time
}
