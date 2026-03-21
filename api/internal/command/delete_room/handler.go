package delete_room

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

func NewHandler(writeRepo room.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		roomWriteRepo: writeRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteRoomCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.roomWriteRepo.Delete(ctx, c.ID); err != nil {
		log.Error().Err(err).Str("room_id", c.ID.String()).Msg("failed to delete room")
		return err
	}

	event := &room.RoomDeletedEvent{
		EventType: "RoomDeleted",
		RoomID:    c.ID,
		Timestamp: time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish RoomDeleted event")
		return err
	}

	log.Info().Str("room_id", c.ID.String()).Msg("room deleted")
	return nil
}
