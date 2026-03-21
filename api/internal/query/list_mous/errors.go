package list_mous

import "errors"

var (
	ErrInvalidQuery     = errors.New("invalid list mous query")
	ErrInvalidPartnerID = errors.New("invalid partner id")
)
