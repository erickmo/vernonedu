package valuepropositioncanvas

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName = errors.New("invalid canvas name")
	ErrCanvasNotFound = errors.New("canvas not found")
)

type ValuePropositionCanvas struct {
	ID        uuid.UUID
	Name      string
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewValuePropositionCanvas(name string) (*ValuePropositionCanvas, error) {
	if name == "" {
		return nil, ErrInvalidName
	}

	return &ValuePropositionCanvas{
		ID:        uuid.New(),
		Name:      name,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

func (vpc *ValuePropositionCanvas) UpdateName(name string) error {
	if name == "" {
		return ErrInvalidName
	}
	vpc.Name = name
	vpc.UpdatedAt = time.Now()
	return nil
}

type WriteRepository interface {
	Save(ctx context.Context, vpc *ValuePropositionCanvas) error
	Update(ctx context.Context, vpc *ValuePropositionCanvas) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*ValuePropositionCanvas, error)
	List(ctx context.Context, offset, limit int) ([]*ValuePropositionCanvas, error)
	Search(ctx context.Context, name string, offset, limit int) ([]*ValuePropositionCanvas, error)
}
