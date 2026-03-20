package list_items_by_canvas

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/item"
)

var ErrInvalidQuery = errors.New("invalid list items by canvas query")

type ListItemsByCanvasQuery struct {
	BusinessID uuid.UUID
	CanvasType string
}

type ItemReadModel struct {
	ID         uuid.UUID `json:"id"`
	BusinessID uuid.UUID `json:"business_id"`
	CanvasType string    `json:"canvas_type"`
	SectionID  string    `json:"section_id"`
	Text       string    `json:"text"`
	Note       string    `json:"note"`
	CreatedAt  string    `json:"created_at"`
	UpdatedAt  string    `json:"updated_at"`
}

type Handler struct {
	itemReadRepo item.ReadRepository
}

func NewHandler(itemReadRepo item.ReadRepository) *Handler {
	return &Handler{
		itemReadRepo: itemReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListItemsByCanvasQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	items, err := h.itemReadRepo.ListByBusinessAndCanvas(ctx, q.BusinessID, q.CanvasType)
	if err != nil {
		log.Error().Err(err).Msg("failed to list items by canvas")
		return nil, err
	}

	readModels := make([]*ItemReadModel, len(items))
	for i, it := range items {
		readModels[i] = &ItemReadModel{
			ID:         it.ID,
			BusinessID: it.BusinessID,
			CanvasType: it.CanvasType,
			SectionID:  it.SectionID,
			Text:       it.Text,
			Note:       it.Note,
			CreatedAt:  it.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
			UpdatedAt:  it.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
		}
	}

	return readModels, nil
}
