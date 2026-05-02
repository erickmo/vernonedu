package list_bank_accounts

import "github.com/google/uuid"

type ListBankAccountsQuery struct {
	BranchID        *uuid.UUID
	IncludeInactive bool
}
