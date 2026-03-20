package search_designthinking

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/designthinking"
)

type SearchDesignThinkingQuery struct {
	Name   string
	Offset int
	Limit  int
}

type DesignThinkingReadModel struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	CreatedAt int64     `json:"created_at"`
	UpdatedAt int64     `json:"updated_at"`
}

type SearchResult struct {
	Data   []*DesignThinkingReadModel `json:"data"`
	Total  int                        `json:"total"`
	Offset int                        `json:"offset"`
	Limit  int                        `json:"limit"`
}

type Handler struct {
	dtReadRepo designthinking.ReadRepository
}

func NewHandler(dtReadRepo designthinking.ReadRepository) *Handler {
	return &Handler{
		dtReadRepo: dtReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*SearchDesignThinkingQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	dts, err := h.dtReadRepo.Search(ctx, q.Name, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to search design thinkings")
		return nil, err
	}

	readModels := make([]*DesignThinkingReadModel, len(dts))
	for i, dt := range dts {
		readModels[i] = &DesignThinkingReadModel{
			ID:        dt.ID,
			Name:      dt.Name,
			CreatedAt: dt.CreatedAt.Unix(),
			UpdatedAt: dt.UpdatedAt.Unix(),
		}
	}

	return &SearchResult{
		Data:   readModels,
		Total:  len(dts),
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
