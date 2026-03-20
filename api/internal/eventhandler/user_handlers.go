package eventhandler

import (
	"context"

	"github.com/ThreeDotsLabs/watermill/message"
	"github.com/rs/zerolog/log"
)

func UserCreatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("UserCreated event received - no action configured")
	return nil
}

func UserUpdatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("UserUpdated event received - no action configured")
	return nil
}

func UserDeletedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("UserDeleted event received - no action configured")
	return nil
}
