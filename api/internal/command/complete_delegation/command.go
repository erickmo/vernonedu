package complete_delegation

import (
	"errors"

	"github.com/google/uuid"
)

var ErrInvalidCommand = errors.New("invalid complete delegation command")

type CompleteDelegationCommand struct {
	DelegationID uuid.UUID `validate:"required"`
	Notes        string
}
