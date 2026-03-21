package accept_delegation

import (
	"errors"

	"github.com/google/uuid"
)

var ErrInvalidCommand = errors.New("invalid accept delegation command")

type AcceptDelegationCommand struct {
	DelegationID uuid.UUID `validate:"required"`
}
