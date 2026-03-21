package delete_pr

import "github.com/google/uuid"

type DeletePrCommand struct {
	ID uuid.UUID
}
