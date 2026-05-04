package create_leave_request

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateLeaveRequestCommand struct {
	EmployeeID string `validate:"required"`
	LeaveType  string `validate:"required"`
	StartDate  string `validate:"required"`
	EndDate    string `validate:"required"`
	Reason     string `validate:"required"`
}

type Handler struct {
	writeRepo hrm.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo hrm.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateLeaveRequestCommand)
	if !ok {
		return ErrInvalidCommand
	}

	employeeID, err := uuid.Parse(c.EmployeeID)
	if err != nil {
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

	lr, err := hrm.NewLeaveRequest(employeeID, c.LeaveType, startDate, endDate, c.Reason)
	if err != nil {
		log.Error().Err(err).Msg("failed to create leave request entity")
		return err
	}

	if err := h.writeRepo.SaveLeaveRequest(ctx, lr); err != nil {
		log.Error().Err(err).Msg("failed to save leave request")
		return err
	}

	log.Info().Str("leave_request_id", lr.ID.String()).Msg("leave request created successfully")
	return nil
}
