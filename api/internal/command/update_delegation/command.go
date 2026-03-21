package update_delegation

import (
	"errors"

	"github.com/google/uuid"
)

var ErrInvalidCommand = errors.New("invalid update delegation command")

type UpdateDelegationCommand struct {
	DelegationID uuid.UUID `validate:"required"`
	Title        string
	Description  string
	DueDate      string // RFC3339 or empty string to leave unchanged
	Priority     string
	Notes        string
}
