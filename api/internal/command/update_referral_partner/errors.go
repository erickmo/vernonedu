package update_referral_partner

import "errors"

var (
	ErrInvalidCommand          = errors.New("invalid update referral partner command")
	ErrReferralPartnerNotFound = errors.New("referral partner not found")
)
