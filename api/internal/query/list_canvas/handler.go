package list_canvas

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/valuepropositioncanvas"
)

type ListCanvasQuery struct {
	Offset int
	Limit  int
}

type CanvasReadModel struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	CreatedAt int64     `json:"created_at"`
	UpdatedAt int64     `json:"updated_at"`
}

type ListResult struct {
	Data   []*CanvasReadModel `json:"data"`
	Total  int                `json:"total"`
	Offset int                `json:"offset"`
	Limit  int                `json:"limit"`
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
	q, ok := query.(*ListCanvasQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	canvases, err := h.canvasReadRepo.List(ctx, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list canvases")
		return nil, err
	}

	readModels := make([]*CanvasReadModel, len(canvases))
	for i, c := range canvases {
		readModels[i] = &CanvasReadModel{
			ID:        c.ID,
			Name:      c.Name,
			CreatedAt: c.CreatedAt.Unix(),
			UpdatedAt: c.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  len(canvases),
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
