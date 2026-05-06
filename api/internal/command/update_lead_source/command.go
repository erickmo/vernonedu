package update_lead_source

import "github.com/google/uuid"

type UpdateLeadSourceCommand struct {
	ID       uuid.UUID `validate:"required"`
	Name     string    `validate:"required"`
	IsActive bool
}
