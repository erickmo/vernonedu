package register_user

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"
	"golang.org/x/crypto/bcrypt"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/user"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

var ErrInvalidCommand = errors.New("invalid register user command")

type RegisterUserCommand struct {
	Name     string `validate:"required,min=1"`
	Email    string `validate:"required,email"`
	Password string `validate:"required,min=6"`
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
	registerCmd, ok := cmd.(*RegisterUserCommand)
	if !ok {
		return ErrInvalidCommand
	}

	hashBytes, err := bcrypt.GenerateFromPassword([]byte(registerCmd.Password), 12)
	if err != nil {
		log.Error().Err(err).Msg("failed to hash password")
		return err
	}

	newUser, err := user.NewUser(registerCmd.Name, registerCmd.Email, string(hashBytes), "student")
	if err != nil {
		log.Error().Err(err).Msg("failed to create user domain object")
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

	log.Info().Str("user_id", newUser.ID.String()).Msg("user registered successfully")
	return nil
}
