package search_canvas

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/valuepropositioncanvas"
)

type SearchCanvasQuery struct {
	Name   string
	Offset int
	Limit  int
}

type CanvasReadModel struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	CreatedAt int64     `json:"created_at"`
	UpdatedAt int64     `json:"updated_at"`
}

type SearchResult struct {
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
	q, ok := query.(*SearchCanvasQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	canvases, err := h.canvasReadRepo.Search(ctx, q.Name, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to search canvases")
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

	return &SearchResult{
		Data:   readModels,
		Total:  len(canvases),
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
