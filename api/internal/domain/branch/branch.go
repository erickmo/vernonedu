package branch

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var ErrBranchNotFound = errors.New("branch not found")

type Branch struct {
	ID           uuid.UUID
	Name         string
	City         string
	Address      string
	Region       string
	ContactName  string
	ContactPhone string
	Status       string // "active" | "inactive"
	PartnerID    *uuid.UUID
	PartnerName  string
	IsActive     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type WriteRepository interface {
	Save(ctx context.Context, b *Branch) error
	Update(ctx context.Context, b *Branch) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Branch, error)
	List(ctx context.Context, offset, limit int) ([]*Branch, int, error)
}
