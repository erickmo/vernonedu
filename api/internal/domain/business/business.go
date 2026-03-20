package business

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName      = errors.New("invalid business name")
	ErrBusinessNotFound = errors.New("business not found")
)

type Business struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Name      string
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewBusiness(userID uuid.UUID, name string) (*Business, error) {
	if name == "" {
		return nil, ErrInvalidName
	}

	return &Business{
		ID:        uuid.New(),
		UserID:    userID,
		Name:      name,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

func (b *Business) UpdateName(name string) error {
	if name == "" {
		return ErrInvalidName
	}
	b.Name = name
	b.UpdatedAt = time.Now()
	return nil
}

type WriteRepository interface {
	Save(ctx context.Context, b *Business) error
	Update(ctx context.Context, b *Business) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Business, error)
	List(ctx context.Context, userID uuid.UUID, offset, limit int) ([]*Business, error)
	Search(ctx context.Context, userID uuid.UUID, name string, offset, limit int) ([]*Business, error)
	ListByUserID(ctx context.Context, userID uuid.UUID, offset, limit int) ([]*Business, error)
}
