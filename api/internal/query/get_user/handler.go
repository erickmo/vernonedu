package get_user

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/user"
)

type GetUserQuery struct {
	UserID uuid.UUID
}

type UserReadModel struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	Roles     []string  `json:"roles"`
	CreatedAt int64     `json:"created_at"`
	UpdatedAt int64     `json:"updated_at"`
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
	q, ok := query.(*GetUserQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	u, err := h.userReadRepo.GetByID(ctx, q.UserID)
	if err != nil {
		log.Error().Err(err).Str("user_id", q.UserID.String()).Msg("failed to get user")
		return nil, err
	}

	readModel := &UserReadModel{
		ID:        u.ID,
		Name:      u.Name,
		Email:     u.Email,
		Roles:     u.Roles,
		CreatedAt: u.CreatedAt.Unix(),
		UpdatedAt: u.UpdatedAt.Unix(),
	}

	return readModel, nil
}
