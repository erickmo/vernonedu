package update_mou

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid update mou command")
	ErrInvalidMOUID   = errors.New("invalid mou id")
	ErrMOUNotFound    = errors.New("mou not found")
)
