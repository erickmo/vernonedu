package mark_notification_read

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// MarkNotificationReadCommand marks a single notification as read.
type MarkNotificationReadCommand struct {
	NotificationID uuid.UUID `validate:"required"`
	RecipientID    uuid.UUID `validate:"required"`
}

// Handler handles MarkNotificationReadCommand.
type Handler struct {
	writeRepo notification.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo notification.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*MarkNotificationReadCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.writeRepo.MarkRead(ctx, c.NotificationID, c.RecipientID); err != nil {
		log.Error().Err(err).
			Str("notification_id", c.NotificationID.String()).
			Msg("failed to mark notification as read")
		return err
	}

	log.Info().
		Str("notification_id", c.NotificationID.String()).
		Str("recipient_id", c.RecipientID.String()).
		Msg("notification marked as read")
	return nil
}
