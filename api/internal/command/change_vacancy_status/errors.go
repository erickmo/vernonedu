package change_vacancy_status

import "errors"

var (
	ErrInvalidCommand          = errors.New("invalid command type for change_vacancy_status")
	ErrInvalidStatusTransition = errors.New("invalid status transition")
)
