package delete_user

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/user"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type DeleteUserCommand struct {
	UserID uuid.UUID `validate:"required"`
}

type Handler struct {
	userWriteRepo user.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(userWriteRepo user.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		userWriteRepo: userWriteRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	deleteCmd, ok := cmd.(*DeleteUserCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.userWriteRepo.Delete(ctx, deleteCmd.UserID); err != nil {
		log.Error().Err(err).Str("user_id", deleteCmd.UserID.String()).Msg("failed to delete user")
		return err
	}

	event := &user.UserDeleted{
		UserID:    deleteCmd.UserID,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish UserDeleted event")
		return err
	}

	log.Info().Str("user_id", deleteCmd.UserID.String()).Msg("user deleted successfully")
	return nil
}
