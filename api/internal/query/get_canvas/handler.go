package get_canvas

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/valuepropositioncanvas"
)

type GetCanvasQuery struct {
	CanvasID uuid.UUID
}

type CanvasReadModel struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	CreatedAt int64     `json:"created_at"`
	UpdatedAt int64     `json:"updated_at"`
}

type Handler struct {
	canvasReadRepo valuepropositioncanvas.ReadRepository
}

func NewHandler(canvasReadRepo valuepropositioncanvas.ReadRepository) *Handler {
	return &Handler{
		canvasReadRepo: canvasReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCanvasQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	canvas, err := h.canvasReadRepo.GetByID(ctx, q.CanvasID)
	if err != nil {
		log.Error().Err(err).Str("canvas_id", q.CanvasID.String()).Msg("failed to get canvas")
		return nil, err
	}

	readModel := &CanvasReadModel{
		ID:        canvas.ID,
		Name:      canvas.Name,
		CreatedAt: canvas.CreatedAt.Unix(),
		UpdatedAt: canvas.UpdatedAt.Unix(),
	}

	return readModel, nil
}
