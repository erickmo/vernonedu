package update_room

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/room"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	roomWriteRepo room.WriteRepository
	roomReadRepo  room.ReadRepository
	eventBus      eventbus.EventBus
}

func NewHandler(writeRepo room.WriteRepository, readRepo room.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		roomWriteRepo: writeRepo,
		roomReadRepo:  readRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateRoomCommand)
	if !ok {
		return ErrInvalidCommand
	}

	r, err := h.roomReadRepo.GetByID(ctx, c.ID)
	if err != nil {
		log.Error().Err(err).Str("room_id", c.ID.String()).Msg("room not found")
		return err
	}

	if c.Name == "" {
		return room.ErrInvalidName
	}

	r.Name = c.Name
	r.Capacity = c.Capacity
	r.Floor = c.Floor
	r.Description = c.Description
	r.UpdatedAt = time.Now()
	if c.Facilities == nil {
		r.Facilities = []string{}
	} else {
		r.Facilities = c.Facilities
	}

	if err := h.roomWriteRepo.Update(ctx, r); err != nil {
		log.Error().Err(err).Msg("failed to update room")
		return err
	}

	event := &room.RoomUpdatedEvent{
		EventType: "RoomUpdated",
		RoomID:    r.ID,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish RoomUpdated event")
		return err
	}

	log.Info().Str("room_id", r.ID.String()).Msg("room updated")
	return nil
}
