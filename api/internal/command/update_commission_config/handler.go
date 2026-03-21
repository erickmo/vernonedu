package update_commission_config

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
)

type Handler struct {
	writeRepo settings.CommissionWriteRepository
}

func NewHandler(writeRepo settings.CommissionWriteRepository) *Handler {
	return &Handler{writeRepo: writeRepo}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdateCommissionConfigCommand)
	if !ok {
		return ErrInvalidCommand
	}

	cfg := &settings.CommissionConfig{
		OpLeaderPct:        c.OpLeaderPct,
		OpLeaderBasis:      c.OpLeaderBasis,
		DeptLeaderPct:      c.DeptLeaderPct,
		DeptLeaderBasis:    c.DeptLeaderBasis,
		CourseCreatorPct:   c.CourseCreatorPct,
		CourseCreatorBasis: c.CourseCreatorBasis,
		UpdatedAt:          time.Now(),
	}

	if err := h.writeRepo.Upsert(ctx, cfg); err != nil {
		log.Error().Err(err).Msg("failed to upsert commission config")
		return err
	}

	log.Info().Msg("commission config updated")
	return nil
}
