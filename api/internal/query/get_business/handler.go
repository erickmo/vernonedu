package get_business

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/business"
)

type GetBusinessQuery struct {
	BusinessID uuid.UUID
}

type BusinessReadModel struct {
	ID        uuid.UUID `json:"id"`
	UserID    uuid.UUID `json:"user_id"`
	Name      string    `json:"name"`
	CreatedAt string    `json:"created_at"`
	UpdatedAt string    `json:"updated_at"`
}

type Handler struct {
	businessReadRepo business.ReadRepository
}

func NewHandler(businessReadRepo business.ReadRepository) *Handler {
	return &Handler{
		businessReadRepo: businessReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetBusinessQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	b, err := h.businessReadRepo.GetByID(ctx, q.BusinessID)
	if err != nil {
		log.Error().Err(err).Str("business_id", q.BusinessID.String()).Msg("failed to get business")
		return nil, err
	}

	readModel := &BusinessReadModel{
		ID:        b.ID,
		UserID:    b.UserID,
		Name:      b.Name,
		CreatedAt: b.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt: b.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	return readModel, nil
}
