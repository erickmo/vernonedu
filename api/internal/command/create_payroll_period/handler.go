package create_payroll_period

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreatePayrollPeriodCommand struct {
	Period    string `validate:"required"`
	StartDate string `validate:"required"`
	EndDate   string `validate:"required"`
	Notes     string
}

type Handler struct {
	writeRepo hrm.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo hrm.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreatePayrollPeriodCommand)
	if !ok {
		return ErrInvalidCommand
	}

	startDate, err := time.Parse("2006-01-02", c.StartDate)
	if err != nil {
		return ErrInvalidCommand
	}

	endDate, err := time.Parse("2006-01-02", c.EndDate)
	if err != nil {
		return ErrInvalidCommand
	}

	pp, err := hrm.NewPayrollPeriod(c.Period, startDate, endDate)
	if err != nil {
		log.Error().Err(err).Msg("failed to create payroll period entity")
		return err
	}
	pp.Notes = c.Notes

	if err := h.writeRepo.SavePayrollPeriod(ctx, pp); err != nil {
		log.Error().Err(err).Msg("failed to save payroll period")
		return err
	}

	log.Info().Str("payroll_period_id", pp.ID.String()).Msg("payroll period created successfully")
	return nil
}
