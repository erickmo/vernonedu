package update_post

import (
	"context"
	"errors"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/marketing"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	writeRepo marketing.WriteRepository
	readRepo  marketing.ReadRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo marketing.WriteRepository, readRepo marketing.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdatePostCommand)
	if !ok {
		return ErrInvalidCommand
	}

	post, err := h.readRepo.GetPostByID(ctx, c.ID)
	if err != nil {
		if errors.Is(err, marketing.ErrPostNotFound) {
			return ErrPostNotFound
		}
		log.Error().Err(err).Str("post_id", c.ID.String()).Msg("failed to get post")
		return err
	}

	if len(c.Platforms) > 0 {
		post.Platforms = c.Platforms
	}
	if c.ScheduledAt != "" {
		if t, err := time.Parse(time.RFC3339, c.ScheduledAt); err == nil {
			post.ScheduledAt = t
		}
	}
	if c.ContentType != "" {
		post.ContentType = c.ContentType
	}
	if c.Caption != "" {
		post.Caption = c.Caption
	}
	if c.MediaURL != "" {
		post.MediaURL = c.MediaURL
	}
	if c.BatchID != nil {
		post.BatchID = c.BatchID
	}
	if c.Status != "" {
		post.Status = c.Status
	}
	post.UpdatedAt = time.Now()

	if err := h.writeRepo.UpdatePost(ctx, post); err != nil {
		log.Error().Err(err).Msg("failed to update post")
		return err
	}

	log.Info().Str("post_id", post.ID.String()).Msg("post updated")
	return nil
}
