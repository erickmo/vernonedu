package create_journal_entry

import "github.com/google/uuid"

type CreateJournalEntryCommand struct {
	TransactionID uuid.UUID `validate:"required"`
	AccountID     uuid.UUID `validate:"required"`
	Debit         float64
	Credit        float64
	Description   string `validate:"required"`
	Source        string `validate:"required"`
}
