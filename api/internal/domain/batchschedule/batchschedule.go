package batchschedule

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrScheduleNotFound   = errors.New("batch schedule not found")
	ErrRoomConflict       = errors.New("room is already booked for the requested time slot")
	ErrInvalidDuration    = errors.New("duration must be greater than zero")
	ErrInvalidScheduledAt = errors.New("scheduled_at must be in the future")
)

const (
	StatusScheduled = "scheduled"
	StatusCompleted = "completed"
	StatusCancelled = "cancelled"
)

// BatchSchedule represents a single session/schedule entry for a course batch.
type BatchSchedule struct {
	ID              uuid.UUID
	CourseBatchID   uuid.UUID
	ModuleID        *uuid.UUID // optional, which module is covered in this session
	RoomID          *uuid.UUID // optional, physical room
	ScheduledAt     time.Time  // when the session starts
	DurationMinutes int        // duration in minutes
	Notes           string
	Status          string // scheduled | completed | cancelled
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

func NewBatchSchedule(courseBatchID uuid.UUID, moduleID, roomID *uuid.UUID, scheduledAt time.Time, durationMinutes int, notes string) (*BatchSchedule, error) {
	if durationMinutes <= 0 {
		return nil, ErrInvalidDuration
	}
	return &BatchSchedule{
		ID:              uuid.New(),
		CourseBatchID:   courseBatchID,
		ModuleID:        moduleID,
		RoomID:          roomID,
		ScheduledAt:     scheduledAt,
		DurationMinutes: durationMinutes,
		Notes:           notes,
		Status:          StatusScheduled,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}, nil
}

// EndTime returns the calculated end time of this schedule.
func (s *BatchSchedule) EndTime() time.Time {
	return s.ScheduledAt.Add(time.Duration(s.DurationMinutes) * time.Minute)
}

// ConflictsWith checks if this schedule overlaps with another (same room required).
func (s *BatchSchedule) ConflictsWith(other *BatchSchedule) bool {
	if s.RoomID == nil || other.RoomID == nil {
		return false
	}
	if *s.RoomID != *other.RoomID {
		return false
	}
	// Overlap if: s.start < other.end AND s.end > other.start
	sEnd := s.EndTime()
	oEnd := other.EndTime()
	return s.ScheduledAt.Before(oEnd) && sEnd.After(other.ScheduledAt)
}

// WriteRepository defines write operations for BatchSchedule.
type WriteRepository interface {
	Save(ctx context.Context, s *BatchSchedule) error
	Update(ctx context.Context, s *BatchSchedule) error
	Delete(ctx context.Context, id uuid.UUID) error
}

// ReadRepository defines read operations for BatchSchedule.
type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*BatchSchedule, error)
	ListByBatch(ctx context.Context, courseBatchID uuid.UUID) ([]*BatchSchedule, error)
	// CheckRoomConflict checks if a room is booked in the time window [from, to].
	// Excludes the given scheduleID (for updates, use uuid.Nil for creates).
	CheckRoomConflict(ctx context.Context, roomID uuid.UUID, from, to time.Time, excludeID uuid.UUID) (bool, error)
}
