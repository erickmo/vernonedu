package update_partner

import "errors"

var (
	ErrInvalidCommand   = errors.New("invalid update partner command")
	ErrInvalidPartnerID = errors.New("invalid partner id")
	ErrPartnerNotFound  = errors.New("partner not found")
)
