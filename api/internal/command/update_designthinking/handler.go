package update_designthinking

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/designthinking"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type UpdateDesignThinkingCommand struct {
	DesignThinkingID uuid.UUID `validate:"required"`
	Name             string    `validate:"required,min=1"`
}

type Handler struct {
	dtReadRepo  designthinking.ReadRepository
	dtWriteRepo designthinking.WriteRepository
	eventBus    eventbus.EventBus
}

func NewHandler(dtReadRepo designthinking.ReadRepository, dtWriteRepo designthinking.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		dtReadRepo:  dtReadRepo,
		dtWriteRepo: dtWriteRepo,
		eventBus:    eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateDesignThinkingCommand)
	if !ok {
		return errors.New("invalid update design thinking command")
	}

	existingDT, err := h.dtReadRepo.GetByID(ctx, updateCmd.DesignThinkingID)
	if err != nil {
		if errors.Is(err, designthinking.ErrNotFound) {
			return designthinking.ErrNotFound
		}
		log.Error().Err(err).Str("design_thinking_id", updateCmd.DesignThinkingID.String()).Msg("failed to get design thinking")
		return err
	}

	if err := existingDT.UpdateName(updateCmd.Name); err != nil {
		log.Error().Err(err).Msg("failed to update design thinking name")
		return err
	}

	if err := h.dtWriteRepo.Update(ctx, existingDT); err != nil {
		log.Error().Err(err).Msg("failed to update design thinking")
		return err
	}

	event := &designthinking.DesignThinkingUpdated{
		DesignThinkingID: existingDT.ID,
		Name:             existingDT.Name,
		Timestamp:        time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish design thinking updated event")
		return err
	}

	log.Info().Str("design_thinking_id", existingDT.ID.String()).Msg("design thinking updated successfully")
	return nil
}
