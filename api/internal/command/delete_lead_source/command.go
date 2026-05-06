package delete_lead_source

import "github.com/google/uuid"

type DeleteLeadSourceCommand struct {
	ID uuid.UUID `validate:"required"`
}
