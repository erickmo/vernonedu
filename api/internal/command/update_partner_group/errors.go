package update_partner_group

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid update partner group command")
	ErrInvalidGroupID = errors.New("invalid partner group id")
)
