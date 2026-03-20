package get_item

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/item"
)

type GetItemQuery struct {
	ItemID uuid.UUID
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
	q, ok := query.(*GetItemQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	i, err := h.itemReadRepo.GetByID(ctx, q.ItemID)
	if err != nil {
		log.Error().Err(err).Str("item_id", q.ItemID.String()).Msg("failed to get item")
		return nil, err
	}

	readModel := &ItemReadModel{
		ID:         i.ID,
		BusinessID: i.BusinessID,
		CanvasType: i.CanvasType,
		SectionID:  i.SectionID,
		Text:       i.Text,
		Note:       i.Note,
		CreatedAt:  i.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:  i.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	return readModel, nil
}
