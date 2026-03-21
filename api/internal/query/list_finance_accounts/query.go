package list_finance_accounts

import "github.com/google/uuid"

type ListFinanceAccountsQuery struct {
	BranchID *uuid.UUID
}
