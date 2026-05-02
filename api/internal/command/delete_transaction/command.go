package delete_transaction

import "github.com/google/uuid"

type DeleteTransactionCommand struct {
	ID uuid.UUID `validate:"required"`
}
