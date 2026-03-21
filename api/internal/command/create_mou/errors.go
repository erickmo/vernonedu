package create_mou

import "errors"

var (
	ErrInvalidCommand   = errors.New("invalid create mou command")
	ErrInvalidPartnerID = errors.New("invalid partner id")
)
