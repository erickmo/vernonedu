package eventhandler

import (
	"context"

	"github.com/ThreeDotsLabs/watermill/message"
	"github.com/rs/zerolog/log"
)

func DesignThinkingCreatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("DesignThinkingCreated event received - no action configured")
	return nil
}

func DesignThinkingUpdatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("DesignThinkingUpdated event received - no action configured")
	return nil
}

func DesignThinkingDeletedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("DesignThinkingDeleted event received - no action configured")
	return nil
}
