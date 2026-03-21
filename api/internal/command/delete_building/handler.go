package delete_building

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	buildingWriteRepo building.WriteRepository
	eventBus          eventbus.EventBus
}

func NewHandler(writeRepo building.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		buildingWriteRepo: writeRepo,
		eventBus:          eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeleteBuildingCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.buildingWriteRepo.Delete(ctx, c.ID); err != nil {
		log.Error().Err(err).Str("building_id", c.ID.String()).Msg("failed to delete building")
		return err
	}

	event := &building.BuildingDeletedEvent{
		EventType:  "BuildingDeleted",
		BuildingID: c.ID,
		Timestamp:  time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish BuildingDeleted event")
		return err
	}

	log.Info().Str("building_id", c.ID.String()).Msg("building deleted")
	return nil
}
