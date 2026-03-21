package lead

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName  = errors.New("invalid lead name")
	ErrLeadNotFound = errors.New("lead not found")
)

type Lead struct {
	ID        uuid.UUID
	Name      string
	Email     string
	Phone     string
	Interest  string
	Source    string
	Notes     string
	Status    string
	CreatedAt time.Time
	UpdatedAt time.Time
}

func NewLead(name, email, phone, interest, source, notes string) (*Lead, error) {
	if name == "" {
		return nil, ErrInvalidName
	}

	if source == "" {
		source = "other"
	}

	return &Lead{
		ID:        uuid.New(),
		Name:      name,
		Email:     email,
		Phone:     phone,
		Interest:  interest,
		Source:    source,
		Notes:     notes,
		Status:    "new",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

type WriteRepository interface {
	Save(ctx context.Context, l *Lead) error
	Update(ctx context.Context, l *Lead) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Lead, error)
	List(ctx context.Context, offset, limit int, status string) ([]*Lead, int, error)
}
