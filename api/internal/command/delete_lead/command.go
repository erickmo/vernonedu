package delete_lead

import "github.com/google/uuid"

type DeleteLeadCommand struct {
	ID uuid.UUID `validate:"required"`
}
