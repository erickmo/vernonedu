package list_business

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/business"
)

type ListBusinessQuery struct {
	UserID uuid.UUID
	Offset int
	Limit  int
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
	q, ok := query.(*ListBusinessQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	businesses, err := h.businessReadRepo.List(ctx, q.UserID, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list businesses")
		return nil, err
	}

	readModels := make([]*BusinessReadModel, len(businesses))
	for i, b := range businesses {
		readModels[i] = &BusinessReadModel{
			ID:        b.ID,
			UserID:    b.UserID,
			Name:      b.Name,
			CreatedAt: b.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
			UpdatedAt: b.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
		}
	}

	return readModels, nil
}
