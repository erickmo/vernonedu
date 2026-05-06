package mark_royalty_paid

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid command type")
	ErrAlreadyPaid    = errors.New("royalty payment record is already paid")
)
