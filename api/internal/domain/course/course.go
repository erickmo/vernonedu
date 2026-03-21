package course

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName  = errors.New("invalid course name")
	ErrCourseNotFound = errors.New("course not found")
)

type Course struct {
	ID           uuid.UUID
	Name         string
	Description  string
	DepartmentID *uuid.UUID
	OwnerID      *uuid.UUID
	IsActive     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

func NewCourse(name, description string, isActive bool) (*Course, error) {
	if name == "" {
		return nil, ErrInvalidName
	}

	return &Course{
		ID:          uuid.New(),
		Name:        name,
		Description: description,
		IsActive:    isActive,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}, nil
}

func (c *Course) UpdateName(name string) error {
	if name == "" {
		return ErrInvalidName
	}
	c.Name = name
	c.UpdatedAt = time.Now()
	return nil
}

type WriteRepository interface {
	Save(ctx context.Context, c *Course) error
	Update(ctx context.Context, c *Course) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Course, error)
	List(ctx context.Context, offset, limit int) ([]*Course, int, error)
}
