package create_post

import (
	"context"
	"time"

	"github.com/google/uuid"
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
	c, ok := cmd.(*CreatePostCommand)
	if !ok {
		return ErrInvalidCommand
	}

	scheduledAt, err := time.Parse(time.RFC3339, c.ScheduledAt)
	if err != nil {
		scheduledAt = time.Now()
	}

	status := "scheduled"
	if c.ScheduledAt == "" {
		status = "draft"
	}

	now := time.Now()
	post := &marketing.SocialMediaPost{
		ID:          uuid.New(),
		Platforms:   c.Platforms,
		ScheduledAt: scheduledAt,
		ContentType: c.ContentType,
		Caption:     c.Caption,
		MediaURL:    c.MediaURL,
		BatchID:     c.BatchID,
		Status:      status,
		CreatedBy:   c.CreatedBy,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	if err := h.writeRepo.SavePost(ctx, post); err != nil {
		log.Error().Err(err).Msg("failed to save post")
		return err
	}

	log.Info().Str("post_id", post.ID.String()).Msg("post created")
	return nil
}
