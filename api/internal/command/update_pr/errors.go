package update_pr

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid update pr command")
	ErrPrNotFound     = errors.New("pr schedule not found")
)
