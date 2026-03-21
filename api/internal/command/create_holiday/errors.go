package create_holiday

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid create holiday command")
	ErrInvalidDate    = errors.New("invalid holiday date format, expected YYYY-MM-DD")
)
