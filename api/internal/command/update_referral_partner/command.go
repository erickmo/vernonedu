package update_referral_partner

import "github.com/google/uuid"

type UpdateReferralPartnerCommand struct {
	ID              uuid.UUID `validate:"required"`
	Name            string
	ContactEmail    string
	CommissionType  string
	CommissionValue float64
	IsActive        *bool
}
