package delete_partner

import "errors"

var (
	ErrInvalidCommand   = errors.New("invalid delete partner command")
	ErrInvalidPartnerID = errors.New("invalid partner id")
)
