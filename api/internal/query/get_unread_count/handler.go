package get_unread_count

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
)

// GetUnreadCountQuery returns the number of unread notifications for a recipient.
type GetUnreadCountQuery struct {
	RecipientID uuid.UUID
}

// UnreadCountResult is the API response shape.
type UnreadCountResult struct {
	Count int `json:"count"`
}

// Handler handles GetUnreadCountQuery.
type Handler struct {
	readRepo notification.ReadRepository
}

func NewHandler(readRepo notification.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetUnreadCountQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	count, err := h.readRepo.GetUnreadCount(ctx, q.RecipientID)
	if err != nil {
		log.Error().Err(err).Str("recipient_id", q.RecipientID.String()).Msg("failed to get unread count")
		return nil, err
	}

	return &UnreadCountResult{Count: count}, nil
}
