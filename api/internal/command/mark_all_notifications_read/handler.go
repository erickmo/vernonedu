package mark_all_notifications_read

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// MarkAllNotificationsReadCommand marks all notifications for a recipient as read.
type MarkAllNotificationsReadCommand struct {
	RecipientID uuid.UUID `validate:"required"`
}

// Handler handles MarkAllNotificationsReadCommand.
type Handler struct {
	writeRepo notification.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo notification.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*MarkAllNotificationsReadCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.writeRepo.MarkAllRead(ctx, c.RecipientID); err != nil {
		log.Error().Err(err).
			Str("recipient_id", c.RecipientID.String()).
			Msg("failed to mark all notifications as read")
		return err
	}

	log.Info().
		Str("recipient_id", c.RecipientID.String()).
		Msg("all notifications marked as read")
	return nil
}
