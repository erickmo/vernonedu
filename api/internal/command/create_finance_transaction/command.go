package create_finance_transaction

import "github.com/google/uuid"

type CreateFinanceTransactionCommand struct {
	Description     string    `validate:"required"`
	AccountDebitID  uuid.UUID `validate:"required"`
	AccountCreditID uuid.UUID `validate:"required"`
	Amount          float64   `validate:"required,gt=0"`
	Reference       string
	BranchID        uuid.UUID `validate:"required"`
	AttachmentURL   string
	CreatedBy       uuid.UUID `validate:"required"`
}
