package get_general_ledger

import "errors"

var (
	ErrInvalidQuery    = errors.New("invalid get general ledger query")
	ErrMissingAccount  = errors.New("account_code is required")
)
