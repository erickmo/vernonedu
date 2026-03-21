package update_pr

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
	c, ok := cmd.(*UpdatePrCommand)
	if !ok {
		return ErrInvalidCommand
	}

	pr, err := h.readRepo.GetPrByID(ctx, c.ID)
	if err != nil {
		if errors.Is(err, marketing.ErrPrNotFound) {
			return ErrPrNotFound
		}
		log.Error().Err(err).Str("pr_id", c.ID.String()).Msg("failed to get pr schedule")
		return err
	}

	if c.Title != "" {
		pr.Title = c.Title
	}
	if c.Type != "" {
		pr.Type = c.Type
	}
	if c.ScheduledAt != "" {
		if t, err := time.Parse(time.RFC3339, c.ScheduledAt); err == nil {
			pr.ScheduledAt = t
		}
	}
	if c.MediaVenue != "" {
		pr.MediaVenue = c.MediaVenue
	}
	if c.PicID != nil {
		pr.PicID = c.PicID
	}
	if c.PicName != "" {
		pr.PicName = c.PicName
	}
	if c.Status != "" {
		pr.Status = c.Status
	}
	if c.Notes != "" {
		pr.Notes = c.Notes
	}
	pr.UpdatedAt = time.Now()

	if err := h.writeRepo.UpdatePr(ctx, pr); err != nil {
		log.Error().Err(err).Msg("failed to update pr schedule")
		return err
	}

	log.Info().Str("pr_id", pr.ID.String()).Msg("pr schedule updated")
	return nil
}
