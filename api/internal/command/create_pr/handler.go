package create_pr

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
	c, ok := cmd.(*CreatePrCommand)
	if !ok {
		return ErrInvalidCommand
	}

	scheduledAt, err := time.Parse(time.RFC3339, c.ScheduledAt)
	if err != nil {
		scheduledAt = time.Now()
	}

	now := time.Now()
	pr := &marketing.PrSchedule{
		ID:          uuid.New(),
		Title:       c.Title,
		Type:        c.Type,
		ScheduledAt: scheduledAt,
		MediaVenue:  c.MediaVenue,
		PicID:       c.PicID,
		PicName:     c.PicName,
		Status:      "scheduled",
		Notes:       c.Notes,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	if err := h.writeRepo.SavePr(ctx, pr); err != nil {
		log.Error().Err(err).Msg("failed to save pr schedule")
		return err
	}

	log.Info().Str("pr_id", pr.ID.String()).Msg("pr schedule created")
	return nil
}
