package update_enrollment_status

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid update enrollment status command")
	ErrInvalidStatus  = errors.New("invalid enrollment status, must be: active, completed, dropped, withdrawn")
)
