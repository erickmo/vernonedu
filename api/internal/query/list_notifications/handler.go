package list_notifications

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
)

// ListNotificationsQuery fetches paginated notifications for a recipient.
type ListNotificationsQuery struct {
	RecipientID uuid.UUID
	Offset      int
	Limit       int
	OnlyUnread  bool
	Type        string
}

// NotificationReadModel is the API response shape.
type NotificationReadModel struct {
	ID          string                 `json:"id"`
	RecipientID string                 `json:"recipient_id"`
	Type        string                 `json:"type"`
	Title       string                 `json:"title"`
	Body        string                 `json:"body"`
	Channel     string                 `json:"channel"`
	Metadata    map[string]interface{} `json:"metadata"`
	IsRead      bool                   `json:"is_read"`
	ReadAt      *int64                 `json:"read_at,omitempty"`
	CreatedAt   int64                  `json:"created_at"`
}

// ListNotificationsResult wraps paginated results.
type ListNotificationsResult struct {
	Data  []*NotificationReadModel `json:"data"`
	Total int                      `json:"total"`
}

// Handler handles ListNotificationsQuery.
type Handler struct {
	readRepo notification.ReadRepository
}

func NewHandler(readRepo notification.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListNotificationsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	limit := q.Limit
	if limit == 0 {
		limit = 20
	}

	items, total, err := h.readRepo.ListByRecipient(ctx, q.RecipientID, q.Offset, limit, q.OnlyUnread, q.Type)
	if err != nil {
		log.Error().Err(err).Str("recipient_id", q.RecipientID.String()).Msg("failed to list notifications")
		return nil, err
	}

	models := make([]*NotificationReadModel, len(items))
	for i, n := range items {
		models[i] = toReadModel(n)
	}

	return &ListNotificationsResult{Data: models, Total: total}, nil
}

func toReadModel(n *notification.Notification) *NotificationReadModel {
	m := &NotificationReadModel{
		ID:          n.ID.String(),
		RecipientID: n.RecipientID.String(),
		Type:        n.Type,
		Title:       n.Title,
		Body:        n.Body,
		Channel:     n.Channel,
		Metadata:    n.Metadata,
		IsRead:      n.IsRead(),
		CreatedAt:   n.CreatedAt.Unix(),
	}
	if n.ReadAt != nil {
		ts := n.ReadAt.Unix()
		m.ReadAt = &ts
	}
	return m
}

// formatTime is a utility for optional time formatting.
func formatTime(t *time.Time) *string {
	if t == nil {
		return nil
	}
	s := t.Format(time.RFC3339)
	return &s
}
