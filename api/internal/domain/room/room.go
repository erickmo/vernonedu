package room

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName  = errors.New("room name is required")
	ErrRoomNotFound = errors.New("room not found")
)

type Room struct {
	ID          uuid.UUID
	BuildingID  uuid.UUID
	Name        string
	Capacity    *int
	Floor       *string
	Facilities  []string
	Description string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// ScheduleConflict represents a booking that conflicts with a requested time window.
type ScheduleConflict struct {
	ScheduleID uuid.UUID
	BatchID    uuid.UUID
	BatchName  string
	StartAt    time.Time
	EndAt      time.Time
}

func NewRoom(buildingID uuid.UUID, name string, capacity *int, floor *string, facilities []string, description string) (*Room, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	if facilities == nil {
		facilities = []string{}
	}
	return &Room{
		ID:          uuid.New(),
		BuildingID:  buildingID,
		Name:        name,
		Capacity:    capacity,
		Floor:       floor,
		Facilities:  facilities,
		Description: description,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}, nil
}

type WriteRepository interface {
	Save(ctx context.Context, r *Room) error
	Update(ctx context.Context, r *Room) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Room, error)
	List(ctx context.Context, buildingID string, offset, limit int) ([]*Room, int, error)
	CheckAvailability(ctx context.Context, roomID uuid.UUID, from, to time.Time) ([]*ScheduleConflict, error)
}
