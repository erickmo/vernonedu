package add_lead_interest

import "github.com/google/uuid"

type AddLeadInterestCommand struct {
	LeadID     uuid.UUID `validate:"required"`
	EntityType string    `validate:"required"`
	EntityID   uuid.UUID `validate:"required"`
}
