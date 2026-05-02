package update_transaction

import "github.com/google/uuid"

type UpdateTransactionCommand struct {
	ID          uuid.UUID `validate:"required"`
	Description string    `validate:"required"`
	Category    string
}
