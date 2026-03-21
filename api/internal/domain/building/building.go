package building

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName      = errors.New("building name is required")
	ErrBuildingNotFound = errors.New("building not found")
)

type Building struct {
	ID          uuid.UUID
	Name        string
	Address     string
	Description string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

func NewBuilding(name, address, description string) (*Building, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	return &Building{
		ID:          uuid.New(),
		Name:        name,
		Address:     address,
		Description: description,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}, nil
}

type WriteRepository interface {
	Save(ctx context.Context, b *Building) error
	Update(ctx context.Context, b *Building) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Building, error)
	List(ctx context.Context, offset, limit int) ([]*Building, int, error)
}
