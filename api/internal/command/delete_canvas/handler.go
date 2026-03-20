package delete_canvas

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/valuepropositioncanvas"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type DeleteCanvasCommand struct {
	CanvasID uuid.UUID `validate:"required"`
}

type Handler struct {
	canvasWriteRepo valuepropositioncanvas.WriteRepository
	eventBus        eventbus.EventBus
}

func NewHandler(canvasWriteRepo valuepropositioncanvas.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		canvasWriteRepo: canvasWriteRepo,
		eventBus:        eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	deleteCmd, ok := cmd.(*DeleteCanvasCommand)
	if !ok {
		return errors.New("invalid delete canvas command")
	}

	if err := h.canvasWriteRepo.Delete(ctx, deleteCmd.CanvasID); err != nil {
		log.Error().Err(err).Str("canvas_id", deleteCmd.CanvasID.String()).Msg("failed to delete canvas")
		return err
	}

	event := &valuepropositioncanvas.ValuePropositionCanvasDeleted{
		CanvasID:  deleteCmd.CanvasID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish canvas deleted event")
		return err
	}

	log.Info().Str("canvas_id", deleteCmd.CanvasID.String()).Msg("canvas deleted successfully")
	return nil
}
