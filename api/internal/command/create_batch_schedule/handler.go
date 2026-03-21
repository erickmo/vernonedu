package create_batch_schedule

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/batchschedule"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

var ErrInvalidCommand = errors.New("invalid create batch schedule command")

type CreateBatchScheduleCommand struct {
	CourseBatchID   uuid.UUID `validate:"required"`
	ModuleID        string    // optional UUID string
	RoomID          string    // optional UUID string
	ScheduledAt     time.Time `validate:"required"`
	DurationMinutes int       `validate:"required,min=1"`
	Notes           string
}

type Handler struct {
	writeRepo batchschedule.WriteRepository
	readRepo  batchschedule.ReadRepository
}

func NewHandler(writeRepo batchschedule.WriteRepository, readRepo batchschedule.ReadRepository) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateBatchScheduleCommand)
	if !ok {
		return ErrInvalidCommand
	}

	var moduleID *uuid.UUID
	if c.ModuleID != "" {
		if id, err := uuid.Parse(c.ModuleID); err == nil {
			moduleID = &id
		}
	}

	var roomID *uuid.UUID
	if c.RoomID != "" {
		if id, err := uuid.Parse(c.RoomID); err == nil {
			roomID = &id
		}
	}

	// Check room conflict if room is specified
	if roomID != nil {
		endTime := c.ScheduledAt.Add(time.Duration(c.DurationMinutes) * time.Minute)
		conflict, err := h.readRepo.CheckRoomConflict(ctx, *roomID, c.ScheduledAt, endTime, uuid.Nil)
		if err != nil {
			log.Error().Err(err).Msg("failed to check room conflict")
			return err
		}
		if conflict {
			return batchschedule.ErrRoomConflict
		}
	}

	s, err := batchschedule.NewBatchSchedule(c.CourseBatchID, moduleID, roomID, c.ScheduledAt, c.DurationMinutes, c.Notes)
	if err != nil {
		return err
	}

	if err := h.writeRepo.Save(ctx, s); err != nil {
		log.Error().Err(err).Msg("failed to save batch schedule")
		return err
	}

	log.Info().Str("schedule_id", s.ID.String()).Msg("batch schedule created")
	return nil
}
