package create_room

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
	eventBus      eventbus.EventBus
}

func NewHandler(roomWriteRepo room.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		roomWriteRepo: roomWriteRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateRoomCommand)
	if !ok {
		return ErrInvalidCommand
	}

	r, err := room.NewRoom(c.BuildingID, c.Name, c.Capacity, c.Floor, c.Facilities, c.Description)
	if err != nil {
		log.Error().Err(err).Msg("failed to create room entity")
		return err
	}

	if err := h.roomWriteRepo.Save(ctx, r); err != nil {
		log.Error().Err(err).Msg("failed to save room")
		return err
	}

	event := &room.RoomCreatedEvent{
		EventType: "RoomCreated",
		RoomID:    r.ID,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish RoomCreated event")
		return err
	}

	log.Info().Str("room_id", r.ID.String()).Msg("room created")
	return nil
}
