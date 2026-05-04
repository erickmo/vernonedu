package create_payroll_item

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreatePayrollItemCommand struct {
	PayrollPeriodID     string  `validate:"required"`
	EmployeeID          string  `validate:"required"`
	BaseSalary          float64
	FacilitatorSessions int
	FacilitatorFee      float64
	AttendanceDeduction float64
	Bonus               float64
	TotalAmount         float64
	Notes               string
}

type Handler struct {
	writeRepo hrm.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo hrm.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreatePayrollItemCommand)
	if !ok {
		return ErrInvalidCommand
	}

	periodID, err := uuid.Parse(c.PayrollPeriodID)
	if err != nil {
		return ErrInvalidCommand
	}

	employeeID, err := uuid.Parse(c.EmployeeID)
	if err != nil {
		return ErrInvalidCommand
	}

	item := hrm.NewPayrollItem(periodID, employeeID, c.BaseSalary, c.FacilitatorFee,
		c.AttendanceDeduction, c.Bonus, c.TotalAmount)
	item.FacilitatorSessions = c.FacilitatorSessions
	item.Notes = c.Notes

	if err := h.writeRepo.SavePayrollItem(ctx, item); err != nil {
		log.Error().Err(err).Msg("failed to save payroll item")
		return err
	}

	log.Info().Str("payroll_item_id", item.ID.String()).Msg("payroll item created successfully")
	return nil
}
