package delete_designthinking

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

type DeleteDesignThinkingCommand struct {
	DesignThinkingID uuid.UUID `validate:"required"`
}

type Handler struct {
	dtWriteRepo designthinking.WriteRepository
	eventBus    eventbus.EventBus
}

func NewHandler(dtWriteRepo designthinking.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		dtWriteRepo: dtWriteRepo,
		eventBus:    eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	deleteCmd, ok := cmd.(*DeleteDesignThinkingCommand)
	if !ok {
		return errors.New("invalid delete design thinking command")
	}

	if err := h.dtWriteRepo.Delete(ctx, deleteCmd.DesignThinkingID); err != nil {
		log.Error().Err(err).Str("design_thinking_id", deleteCmd.DesignThinkingID.String()).Msg("failed to delete design thinking")
		return err
	}

	event := &designthinking.DesignThinkingDeleted{
		DesignThinkingID: deleteCmd.DesignThinkingID,
		Timestamp:        time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish design thinking deleted event")
		return err
	}

	log.Info().Str("design_thinking_id", deleteCmd.DesignThinkingID.String()).Msg("design thinking deleted successfully")
	return nil
}
