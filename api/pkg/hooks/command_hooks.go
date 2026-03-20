package hooks

import (
	"context"

	"github.com/go-playground/validator/v10"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type ValidationHook struct {
	validator *validator.Validate
}

func NewValidationHook() *ValidationHook {
	return &ValidationHook{
		validator: validator.New(),
	}
}

func (h *ValidationHook) Before(ctx context.Context, cmd commandbus.Command) error {
	if err := h.validator.StructCtx(ctx, cmd); err != nil {
		log.Debug().Err(err).Msg("command validation failed")
		return err
	}
	return nil
}

func (h *ValidationHook) After(ctx context.Context, cmd commandbus.Command, err error) error {
	return nil
}

type LoggingHook struct{}

func NewLoggingHook() *LoggingHook {
	return &LoggingHook{}
}

func (h *LoggingHook) Before(ctx context.Context, cmd commandbus.Command) error {
	log.Info().Str("command_type", commandbus.GetCommandType(cmd)).Msg("command hook: before")
	return nil
}

func (h *LoggingHook) After(ctx context.Context, cmd commandbus.Command, err error) error {
	if err != nil {
		log.Error().Err(err).Str("command_type", commandbus.GetCommandType(cmd)).Msg("command hook: after (error)")
		return nil
	}
	log.Info().Str("command_type", commandbus.GetCommandType(cmd)).Msg("command hook: after (success)")
	return nil
}

// Helper function untuk mendapatkan command type name
func GetCommandType(cmd commandbus.Command) string {
	return commandbus.GetCommandType(cmd)
}
