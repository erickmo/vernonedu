package create_building

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

func NewHandler(buildingWriteRepo building.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		buildingWriteRepo: buildingWriteRepo,
		eventBus:          eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateBuildingCommand)
	if !ok {
		return ErrInvalidCommand
	}

	b, err := building.NewBuilding(c.Name, c.Address, c.Description)
	if err != nil {
		log.Error().Err(err).Msg("failed to create building entity")
		return err
	}

	if err := h.buildingWriteRepo.Save(ctx, b); err != nil {
		log.Error().Err(err).Msg("failed to save building")
		return err
	}

	event := &building.BuildingCreatedEvent{
		EventType:  "BuildingCreated",
		BuildingID: b.ID,
		Timestamp:  time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish BuildingCreated event")
		return err
	}

	log.Info().Str("building_id", b.ID.String()).Msg("building created")
	return nil
}
