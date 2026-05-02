package get_investment_plan

import "errors"

var (
	ErrInvalidQuery = errors.New("invalid get investment plan query")
	ErrInvalidID    = errors.New("invalid investment plan id")
)
