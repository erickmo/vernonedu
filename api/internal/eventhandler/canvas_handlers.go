package eventhandler

import (
	"context"

	"github.com/ThreeDotsLabs/watermill/message"
	"github.com/rs/zerolog/log"
)

func CanvasCreatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("ValuePropositionCanvasCreated event received - no action configured")
	return nil
}

func CanvasUpdatedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("ValuePropositionCanvasUpdated event received - no action configured")
	return nil
}

func CanvasDeletedHandler(ctx context.Context, msg *message.Message) error {
	log.Info().Msg("ValuePropositionCanvasDeleted event received - no action configured")
	return nil
}
