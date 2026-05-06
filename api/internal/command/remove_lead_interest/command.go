package remove_lead_interest

import "github.com/google/uuid"

type RemoveLeadInterestCommand struct {
	LeadID     uuid.UUID `validate:"required"`
	InterestID uuid.UUID `validate:"required"`
}
