package delete_mou

import "errors"

var (
	ErrInvalidCommand = errors.New("invalid delete mou command")
	ErrInvalidMOUID   = errors.New("invalid mou id")
)
