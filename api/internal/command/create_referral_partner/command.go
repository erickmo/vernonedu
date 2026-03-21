package create_referral_partner

type CreateReferralPartnerCommand struct {
	Name            string  `validate:"required"`
	ContactEmail    string
	ReferralCode    string  `validate:"required"`
	CommissionType  string  `validate:"required"`
	CommissionValue float64
}
