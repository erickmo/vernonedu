package update_enrollment_payment_status

import "errors"

var (
	ErrInvalidCommand       = errors.New("invalid update enrollment payment status command")
	ErrInvalidPaymentStatus = errors.New("invalid payment status, must be: pending, paid, failed")
)
