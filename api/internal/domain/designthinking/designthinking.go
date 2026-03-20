package designthinking

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName = errors.New("invalid design thinking name")
	ErrNotFound = errors.New("design thinking not found")
)

type DesignThinking struct {
	ID        uuid.UUID
	Name      string
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewDesignThinking(name string) (*DesignThinking, error) {
	if name == "" {
		return nil, ErrInvalidName
	}

	return &DesignThinking{
		ID:        uuid.New(),
		Name:      name,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

func (dt *DesignThinking) UpdateName(name string) error {
	if name == "" {
		return ErrInvalidName
	}
	dt.Name = name
	dt.UpdatedAt = time.Now()
	return nil
}

type WriteRepository interface {
	Save(ctx context.Context, dt *DesignThinking) error
	Update(ctx context.Context, dt *DesignThinking) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*DesignThinking, error)
	List(ctx context.Context, offset, limit int) ([]*DesignThinking, error)
	Search(ctx context.Context, name string, offset, limit int) ([]*DesignThinking, error)
}
