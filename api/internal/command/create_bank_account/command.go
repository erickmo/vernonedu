package create_bank_account

import "github.com/google/uuid"

type CreateBankAccountCommand struct {
	ID            uuid.UUID
	BranchID      uuid.UUID `validate:"required"`
	Name          string    `validate:"required"`
	AccountNumber string
	BankName      string
	BalanceCents  int64
	Currency      string
	CoaCode       string
	CreatedBy     *uuid.UUID
}
