package okr

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrObjectiveNotFound = errors.New("okr objective not found")
	ErrKeyResultNotFound = errors.New("okr key result not found")
)

type Objective struct {
	ID         uuid.UUID
	Title      string
	OwnerID    *uuid.UUID
	OwnerName  string
	Period     string
	Level      string
	Status     string
	Progress   int
	KeyResults []*KeyResult
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

type KeyResult struct {
	ID          uuid.UUID
	ObjectiveID uuid.UUID
	Title       string
	Progress    int
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type WriteRepository interface {
	Save(ctx context.Context, o *Objective) error
	Update(ctx context.Context, o *Objective) error
	SaveKeyResult(ctx context.Context, kr *KeyResult) error
	UpdateKeyResultProgress(ctx context.Context, id uuid.UUID, progress int) error
	UpdateKeyResult(ctx context.Context, kr *KeyResult) error
	DeleteKeyResult(ctx context.Context, id uuid.UUID) error
	GetKeyResult(ctx context.Context, id uuid.UUID) (*KeyResult, error)
}

type ReadRepository interface {
	List(ctx context.Context, level string) ([]*Objective, error)
	GetByID(ctx context.Context, id uuid.UUID) (*Objective, error)
}
