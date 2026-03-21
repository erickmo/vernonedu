package create_notification

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// CreateNotificationCommand creates a new notification for a recipient.
type CreateNotificationCommand struct {
	RecipientID uuid.UUID              `validate:"required"`
	Type        string                 `validate:"required"`
	Title       string                 `validate:"required,min=1"`
	Body        string                 `validate:"required,min=1"`
	Channel     string                 `validate:"required"`
	Metadata    map[string]interface{}
}

// Handler handles CreateNotificationCommand.
type Handler struct {
	writeRepo notification.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo notification.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateNotificationCommand)
	if !ok {
		return ErrInvalidCommand
	}

	n := notification.NewNotification(c.RecipientID, c.Type, c.Title, c.Body, c.Channel, c.Metadata)

	if err := h.writeRepo.Save(ctx, n); err != nil {
		log.Error().Err(err).Msg("failed to save notification")
		return err
	}

	log.Info().
		Str("notification_id", n.ID.String()).
		Str("recipient_id", n.RecipientID.String()).
		Str("type", n.Type).
		Msg("notification created")
	return nil
}
