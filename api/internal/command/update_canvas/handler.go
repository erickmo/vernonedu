package update_canvas

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

type UpdateCanvasCommand struct {
	CanvasID uuid.UUID `validate:"required"`
	Name     string    `validate:"required,min=1"`
}

type Handler struct {
	canvasReadRepo  valuepropositioncanvas.ReadRepository
	canvasWriteRepo valuepropositioncanvas.WriteRepository
	eventBus        eventbus.EventBus
}

func NewHandler(canvasReadRepo valuepropositioncanvas.ReadRepository, canvasWriteRepo valuepropositioncanvas.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		canvasReadRepo:  canvasReadRepo,
		canvasWriteRepo: canvasWriteRepo,
		eventBus:        eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateCanvasCommand)
	if !ok {
		return errors.New("invalid update canvas command")
	}

	existingCanvas, err := h.canvasReadRepo.GetByID(ctx, updateCmd.CanvasID)
	if err != nil {
		if errors.Is(err, valuepropositioncanvas.ErrCanvasNotFound) {
			return valuepropositioncanvas.ErrCanvasNotFound
		}
		log.Error().Err(err).Str("canvas_id", updateCmd.CanvasID.String()).Msg("failed to get canvas")
		return err
	}

	if err := existingCanvas.UpdateName(updateCmd.Name); err != nil {
		log.Error().Err(err).Msg("failed to update canvas name")
		return err
	}

	if err := h.canvasWriteRepo.Update(ctx, existingCanvas); err != nil {
		log.Error().Err(err).Msg("failed to update canvas")
		return err
	}

	event := &valuepropositioncanvas.ValuePropositionCanvasUpdated{
		CanvasID:  existingCanvas.ID,
		Name:      existingCanvas.Name,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish canvas updated event")
		return err
	}

	log.Info().Str("canvas_id", existingCanvas.ID.String()).Msg("canvas updated successfully")
	return nil
}
