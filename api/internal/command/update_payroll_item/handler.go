package update_payroll_item

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type UpdatePayrollItemCommand struct {
	ID                  string  `validate:"required"`
	BaseSalary          float64
	FacilitatorSessions int
	FacilitatorFee      float64
	AttendanceDeduction float64
	Bonus               float64
	TotalAmount         float64
	Status              string
	Notes               string
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
	c, ok := cmd.(*UpdatePayrollItemCommand)
	if !ok {
		return ErrInvalidCommand
	}

	id, err := uuid.Parse(c.ID)
	if err != nil {
		return ErrInvalidCommand
	}

	item, err := h.readRepo.GetPayrollItemByID(ctx, id)
	if err != nil {
		log.Error().Err(err).Msg("failed to get payroll item")
		return err
	}

	item.BaseSalary = c.BaseSalary
	item.FacilitatorSessions = c.FacilitatorSessions
	item.FacilitatorFee = c.FacilitatorFee
	item.AttendanceDeduction = c.AttendanceDeduction
	item.Bonus = c.Bonus
	item.TotalAmount = c.TotalAmount
	if c.Status != "" {
		item.Status = c.Status
	}
	item.Notes = c.Notes
	item.UpdatedAt = time.Now()

	if err := h.writeRepo.UpdatePayrollItem(ctx, item); err != nil {
		log.Error().Err(err).Msg("failed to update payroll item")
		return err
	}

	log.Info().Str("payroll_item_id", id.String()).Msg("payroll item updated successfully")
	return nil
}
