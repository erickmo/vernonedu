package update_bank_account

import "github.com/google/uuid"

type UpdateBankAccountCommand struct {
	ID            uuid.UUID `validate:"required"`
	Name          string    `validate:"required"`
	AccountNumber string
	BankName      string
	BalanceCents  int64
	Currency      string
	CoaCode       string
}
