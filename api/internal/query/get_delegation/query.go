package get_delegation

import (
	"errors"

	"github.com/google/uuid"
)

var ErrInvalidQuery = errors.New("invalid get delegation query")

type GetDelegationQuery struct {
	ID uuid.UUID
}
