package create_user

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"
	"golang.org/x/crypto/bcrypt"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/user"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateUserCommand struct {
	Name     string `validate:"required,min=1"`
	Email    string `validate:"required,email"`
	Password string `validate:"required,min=6"`
	Role     string `validate:"required"`
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
	createCmd, ok := cmd.(*CreateUserCommand)
	if !ok {
		return ErrInvalidCommand
	}

	hashBytes, err := bcrypt.GenerateFromPassword([]byte(createCmd.Password), 12)
	if err != nil {
		log.Error().Err(err).Msg("failed to hash password")
		return err
	}

	newUser, err := user.NewUser(createCmd.Name, createCmd.Email, string(hashBytes), createCmd.Role)
	if err != nil {
		log.Error().Err(err).Msg("failed to create user")
		return err
	}

	if err := h.userWriteRepo.Save(ctx, newUser); err != nil {
		log.Error().Err(err).Msg("failed to save user")
		return err
	}

	event := &user.UserCreated{
		UserID:    newUser.ID,
		Name:      newUser.Name,
		Timestamp: time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish UserCreated event")
		return err
	}

	log.Info().Str("user_id", newUser.ID.String()).Msg("user created successfully")
	return nil
}
