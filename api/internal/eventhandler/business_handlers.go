package eventhandler

import (
	"context"

	"github.com/ThreeDotsLabs/watermill/message"
	"github.com/rs/zerolog/log"
)

func BusinessCreatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("BusinessCreated event received - no action configured")
	return nil
}

func BusinessUpdatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("BusinessUpdated event received - no action configured")
	return nil
}

func BusinessDeletedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("BusinessDeleted event received - no action configured")
	return nil
}
