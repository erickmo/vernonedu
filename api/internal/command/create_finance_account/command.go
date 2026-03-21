package create_finance_account

import "github.com/google/uuid"

type CreateFinanceAccountCommand struct {
	Code     string  `validate:"required"`
	Name     string  `validate:"required"`
	Type     string  `validate:"required"`
	ParentID *uuid.UUID
	BranchID *uuid.UUID
}
