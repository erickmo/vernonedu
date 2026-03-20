package list_user

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/user"
)

type ListUserQuery struct {
	Offset int
	Limit  int
}

type UserReadModel struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	Role      string    `json:"role"`
	CreatedAt int64     `json:"created_at"`
	UpdatedAt int64     `json:"updated_at"`
}

type ListResult struct {
	Data   []*UserReadModel `json:"data"`
	Total  int              `json:"total"`
	Offset int              `json:"offset"`
	Limit  int              `json:"limit"`
}

type Handler struct {
	userReadRepo user.ReadRepository
}

func NewHandler(userReadRepo user.ReadRepository) *Handler {
	return &Handler{
		userReadRepo: userReadRepo,
	}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListUserQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	users, err := h.userReadRepo.List(ctx, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list users")
		return nil, err
	}

	readModels := make([]*UserReadModel, len(users))
	for i, u := range users {
		readModels[i] = &UserReadModel{
			ID:        u.ID,
			Name:      u.Name,
			Email:     u.Email,
			Role:      u.Role,
			CreatedAt: u.CreatedAt.Unix(),
			UpdatedAt: u.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  len(users),
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
