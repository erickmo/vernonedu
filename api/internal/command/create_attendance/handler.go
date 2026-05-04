package create_attendance

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateAttendanceCommand struct {
	EmployeeID string  `validate:"required"`
	Date       string  `validate:"required"`
	Status     string  `validate:"required"`
	ClockIn    *string
	ClockOut   *string
	Note       string
}

type Handler struct {
	writeRepo hrm.WriteRepository
	eventBus  eventbus.EventBus
}

func NewHandler(writeRepo hrm.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{writeRepo: writeRepo, eventBus: eventBus}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateAttendanceCommand)
	if !ok {
		return ErrInvalidCommand
	}

	employeeID, err := uuid.Parse(c.EmployeeID)
	if err != nil {
		return ErrInvalidCommand
	}

	date, err := time.Parse("2006-01-02", c.Date)
	if err != nil {
		return ErrInvalidCommand
	}

	attendance := hrm.NewStaffAttendance(employeeID, date, c.Status)
	attendance.Note = c.Note

	if c.ClockIn != nil {
		ci, err := time.Parse(time.RFC3339, *c.ClockIn)
		if err == nil {
			attendance.ClockIn = &ci
		}
	}
	if c.ClockOut != nil {
		co, err := time.Parse(time.RFC3339, *c.ClockOut)
		if err == nil {
			attendance.ClockOut = &co
		}
	}

	if err := h.writeRepo.SaveAttendance(ctx, attendance); err != nil {
		log.Error().Err(err).Msg("failed to save attendance")
		return err
	}

	log.Info().Str("attendance_id", attendance.ID.String()).Msg("attendance created successfully")
	return nil
}
