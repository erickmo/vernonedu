package search_item

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/item"
)

type SearchItemQuery struct {
	BusinessID uuid.UUID
	CanvasType string
	SectionID  string
}

type ItemReadModel struct {
	ID         uuid.UUID `json:"id"`
	BusinessID uuid.UUID `json:"business_id"`
	CanvasType string    `json:"canvas_type"`
	SectionID  string    `json:"section_id"`
	Text       string    `json:"text"`
	Note       string    `json:"note"`
	CreatedAt  int64     `json:"created_at"`
	UpdatedAt  int64     `json:"updated_at"`
}

type SearchResult struct {
	Data  []*ItemReadModel `json:"data"`
	Total int              `json:"total"`
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
	q, ok := query.(*SearchItemQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	items, err := h.itemReadRepo.ListBySection(ctx, q.BusinessID, q.CanvasType, q.SectionID)
	if err != nil {
		log.Error().Err(err).Msg("failed to search items by section")
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
			CreatedAt:  it.CreatedAt.Unix(),
			UpdatedAt:  it.UpdatedAt.Unix(),
		}
	}

	return &SearchResult{
		Data:  readModels,
		Total: len(items),
	}, nil
}
