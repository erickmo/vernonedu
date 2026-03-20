package item

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidText  = errors.New("invalid item text")
	ErrItemNotFound = errors.New("item not found")
)

type Item struct {
	ID         uuid.UUID
	BusinessID uuid.UUID
	CanvasType string
	SectionID  string
	Text       string
	Note       string
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

func NewItem(businessID uuid.UUID, canvasType, sectionID, text, note string) (*Item, error) {
	if text == "" {
		return nil, ErrInvalidText
	}

	return &Item{
		ID:         uuid.New(),
		BusinessID: businessID,
		CanvasType: canvasType,
		SectionID:  sectionID,
		Text:       text,
		Note:       note,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}, nil
}

func (i *Item) Update(text, note string) error {
	if text == "" {
		return ErrInvalidText
	}
	i.Text = text
	i.Note = note
	i.UpdatedAt = time.Now()
	return nil
}

type WriteRepository interface {
	Save(ctx context.Context, i *Item) error
	Update(ctx context.Context, i *Item) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Item, error)
	ListByBusinessAndCanvas(ctx context.Context, businessID uuid.UUID, canvasType string) ([]*Item, error)
	ListBySection(ctx context.Context, businessID uuid.UUID, canvasType, sectionID string) ([]*Item, error)
}
