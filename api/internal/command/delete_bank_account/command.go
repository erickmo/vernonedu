package delete_bank_account

import "github.com/google/uuid"

type DeleteBankAccountCommand struct {
	ID uuid.UUID `validate:"required"`
}
