package update_user

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/user"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type UpdateUserCommand struct {
	UserID uuid.UUID `validate:"required"`
	Name   string    `validate:"required,min=1"`
}

type Handler struct {
	userReadRepo  user.ReadRepository
	userWriteRepo user.WriteRepository
	eventBus      eventbus.EventBus
}

func NewHandler(userReadRepo user.ReadRepository, userWriteRepo user.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		userReadRepo:  userReadRepo,
		userWriteRepo: userWriteRepo,
		eventBus:      eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateUserCommand)
	if !ok {
		return ErrInvalidCommand
	}

	existingUser, err := h.userReadRepo.GetByID(ctx, updateCmd.UserID)
	if err != nil {
		if errors.Is(err, user.ErrUserNotFound) {
			return user.ErrUserNotFound
		}
		log.Error().Err(err).Str("user_id", updateCmd.UserID.String()).Msg("failed to get user")
		return err
	}

	if err := existingUser.UpdateName(updateCmd.Name); err != nil {
		log.Error().Err(err).Msg("failed to update user name")
		return err
	}

	if err := h.userWriteRepo.Update(ctx, existingUser); err != nil {
		log.Error().Err(err).Msg("failed to update user")
		return err
	}

	event := &user.UserUpdated{
		UserID:    existingUser.ID,
		Name:      existingUser.Name,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish UserUpdated event")
		return err
	}

	log.Info().Str("user_id", existingUser.ID.String()).Msg("user updated successfully")
	return nil
}
