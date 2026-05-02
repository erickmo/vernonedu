package update_investment_plan

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid update investment plan command")
	ErrInvalidID      = errors.New("invalid investment plan id")
)
