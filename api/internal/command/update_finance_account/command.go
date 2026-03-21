package update_finance_account

import "github.com/google/uuid"

type UpdateFinanceAccountCommand struct {
	ID       uuid.UUID `validate:"required"`
	Name     string    `validate:"required"`
	IsActive bool
}
