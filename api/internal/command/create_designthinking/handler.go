package create_designthinking

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/designthinking"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateDesignThinkingCommand struct {
	Name string `validate:"required,min=1"`
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
	createCmd, ok := cmd.(*CreateDesignThinkingCommand)
	if !ok {
		return errors.New("invalid create design thinking command")
	}

	newDT, err := designthinking.NewDesignThinking(createCmd.Name)
	if err != nil {
		log.Error().Err(err).Msg("failed to create design thinking")
		return err
	}

	if err := h.dtWriteRepo.Save(ctx, newDT); err != nil {
		log.Error().Err(err).Msg("failed to save design thinking")
		return err
	}

	event := &designthinking.DesignThinkingCreated{
		DesignThinkingID: newDT.ID,
		Name:             newDT.Name,
		Timestamp:        time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish design thinking created event")
		return err
	}

	log.Info().Str("design_thinking_id", newDT.ID.String()).Msg("design thinking created successfully")
	return nil
}
