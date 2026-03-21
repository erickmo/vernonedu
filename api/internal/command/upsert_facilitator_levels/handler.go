package upsert_facilitator_levels

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo settings.FacilitatorLevelWriteRepository
}

func NewHandler(writeRepo settings.FacilitatorLevelWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpsertFacilitatorLevelsCommand)
	if !ok {
		return ErrInvalidCommand
	}

	now := time.Now()
	levels := make([]*settings.FacilitatorLevel, len(c.Levels))
	for i, input := range c.Levels {
		levels[i] = &settings.FacilitatorLevel{
			ID:            uuid.New(),
			Level:         input.Level,
			Name:          input.Name,
			FeePerSession: input.FeePerSession,
			CreatedAt:     now,
			UpdatedAt:     now,
		}
	}

	if err := h.writeRepo.ReplaceAll(ctx, levels); err != nil {
		log.Error().Err(err).Msg("failed to upsert facilitator levels")
		return err
	}

	log.Info().Int("count", len(levels)).Msg("facilitator levels updated")
	return nil
}
