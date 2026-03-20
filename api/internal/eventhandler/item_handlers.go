package eventhandler

import (
	"context"

	"github.com/ThreeDotsLabs/watermill/message"
	"github.com/rs/zerolog/log"
)

func ItemCreatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("ItemCreated event received - no action configured")
	return nil
}

func ItemUpdatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("ItemUpdated event received - no action configured")
	return nil
}

func ItemDeletedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("ItemDeleted event received - no action configured")
	return nil
}
