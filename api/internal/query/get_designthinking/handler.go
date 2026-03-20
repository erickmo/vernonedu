package get_designthinking

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/designthinking"
)

type GetDesignThinkingQuery struct {
	DesignThinkingID uuid.UUID
}

type DesignThinkingReadModel struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	CreatedAt int64     `json:"created_at"`
	UpdatedAt int64     `json:"updated_at"`
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
	q, ok := query.(*GetDesignThinkingQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	dt, err := h.dtReadRepo.GetByID(ctx, q.DesignThinkingID)
	if err != nil {
		log.Error().Err(err).Str("design_thinking_id", q.DesignThinkingID.String()).Msg("failed to get design thinking")
		return nil, err
	}

	readModel := &DesignThinkingReadModel{
		ID:        dt.ID,
		Name:      dt.Name,
		CreatedAt: dt.CreatedAt.Unix(),
		UpdatedAt: dt.UpdatedAt.Unix(),
	}

	return readModel, nil
}
