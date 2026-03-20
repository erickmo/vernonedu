package create_canvas

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/valuepropositioncanvas"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateCanvasCommand struct {
	Name string `validate:"required,min=1"`
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
	createCmd, ok := cmd.(*CreateCanvasCommand)
	if !ok {
		return errors.New("invalid create canvas command")
	}

	newCanvas, err := valuepropositioncanvas.NewValuePropositionCanvas(createCmd.Name)
	if err != nil {
		log.Error().Err(err).Msg("failed to create canvas")
		return err
	}

	if err := h.canvasWriteRepo.Save(ctx, newCanvas); err != nil {
		log.Error().Err(err).Msg("failed to save canvas")
		return err
	}

	event := &valuepropositioncanvas.ValuePropositionCanvasCreated{
		CanvasID:  newCanvas.ID,
		Name:      newCanvas.Name,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish canvas created event")
		return err
	}

	log.Info().Str("canvas_id", newCanvas.ID.String()).Msg("canvas created successfully")
	return nil
}
