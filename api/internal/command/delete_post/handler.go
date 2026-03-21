package delete_post

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo marketing.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo marketing.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*DeletePostCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.writeRepo.DeletePost(ctx, c.ID); err != nil {
		log.Error().Err(err).Str("post_id", c.ID.String()).Msg("failed to delete post")
		return err
	}

	log.Info().Str("post_id", c.ID.String()).Msg("post deleted")
	return nil
}
