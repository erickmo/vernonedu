package cancel_delegation

import (
	"errors"

	"github.com/google/uuid"
)

var ErrInvalidCommand = errors.New("invalid cancel delegation command")

type CancelDelegationCommand struct {
	DelegationID uuid.UUID `validate:"required"`
	Notes        string
}
