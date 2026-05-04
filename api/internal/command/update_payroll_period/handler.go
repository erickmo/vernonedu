package update_payroll_period

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type UpdatePayrollPeriodCommand struct {
	ID         string `validate:"required"`
	Status     string `validate:"required,oneof=draft approved disbursed"`
	ApprovedBy string `validate:"omitempty"`
	Notes      string
}

type Handler struct {
	writeRepo hrm.WriteRepository
	readRepo  hrm.ReadRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo hrm.WriteRepository, readRepo hrm.ReadRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, readRepo: readRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*UpdatePayrollPeriodCommand)
	if !ok {
		return ErrInvalidCommand
	}

	id, err := uuid.Parse(c.ID)
	if err != nil {
		return ErrInvalidCommand
	}

	pp, err := h.readRepo.GetPayrollPeriodByID(ctx, id)
	if err != nil {
		log.Error().Err(err).Msg("failed to get payroll period")
		return err
	}

	pp.Status = c.Status
	pp.Notes = c.Notes
	pp.UpdatedAt = time.Now()

	if c.ApprovedBy != "" {
		approvedBy, err := uuid.Parse(c.ApprovedBy)
		if err == nil {
			pp.ApprovedBy = &approvedBy
			now := time.Now()
			pp.ApprovedAt = &now
		}
	}

	if c.Status == "disbursed" {
		now := time.Now()
		pp.DisbursedAt = &now
	}

	if err := h.writeRepo.UpdatePayrollPeriodStatus(ctx, pp); err != nil {
		log.Error().Err(err).Msg("failed to update payroll period")
		return err
	}

	log.Info().Str("payroll_period_id", id.String()).Str("status", c.Status).Msg("payroll period updated")
	return nil
}
