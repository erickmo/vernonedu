package delegation

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var ErrDelegationNotFound = errors.New("delegation not found")

type Delegation struct {
	ID               uuid.UUID
	Title            string
	Type             string
	Description      string
	AssignedToID     *uuid.UUID
	AssignedToName   string
	AssignedByID     *uuid.UUID
	AssignedByName   string
	Priority         string
	Deadline         *time.Time
	Status           string
	LinkedEntityID   string
	LinkedEntityType string
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type WriteRepository interface {
	Save(ctx context.Context, d *Delegation) error
	Update(ctx context.Context, d *Delegation) error
}

type ReadRepository interface {
	List(ctx context.Context, offset, limit int, status, delegationType string) ([]*Delegation, int, error)
	Stats(ctx context.Context) (*DelegationStats, error)
}

type DelegationStats struct {
	ActiveCount             int
	PendingCount            int
	InProgressCount         int
	CompletedThisMonthCount int
}
