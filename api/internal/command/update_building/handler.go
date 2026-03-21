package update_building

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
	buildingReadRepo  building.ReadRepository
	eventBus          eventbus.EventBus
}

func NewHandler(writeRepo building.WriteRepository, readRepo building.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		buildingWriteRepo: writeRepo,
		buildingReadRepo:  readRepo,
		eventBus:          eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateBuildingCommand)
	if !ok {
		return ErrInvalidCommand
	}

	b, err := h.buildingReadRepo.GetByID(ctx, c.ID)
	if err != nil {
		log.Error().Err(err).Str("building_id", c.ID.String()).Msg("building not found")
		return err
	}

	if c.Name == "" {
		return building.ErrInvalidName
	}

	b.Name = c.Name
	b.Address = c.Address
	b.Description = c.Description
	b.UpdatedAt = time.Now()

	if err := h.buildingWriteRepo.Update(ctx, b); err != nil {
		log.Error().Err(err).Msg("failed to update building")
		return err
	}

	event := &building.BuildingUpdatedEvent{
		EventType:  "BuildingUpdated",
		BuildingID: b.ID,
		Timestamp:  time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish BuildingUpdated event")
		return err
	}

	log.Info().Str("building_id", b.ID.String()).Msg("building updated")
	return nil
}
