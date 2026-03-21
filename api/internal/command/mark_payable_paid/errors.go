package mark_payable_paid

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid mark payable paid command")
	ErrNotApproved    = errors.New("payable must be in approved status before marking as paid")
)
