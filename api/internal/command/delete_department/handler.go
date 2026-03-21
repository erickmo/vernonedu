package delete_department

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type DeleteDepartmentCommand struct {
	DepartmentID uuid.UUID `validate:"required"`
}

type Handler struct {
	departmentWriteRepo department.WriteRepository
	eventBus            eventbus.EventBus
}

func NewHandler(departmentWriteRepo department.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		departmentWriteRepo: departmentWriteRepo,
		eventBus:            eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	deleteCmd, ok := cmd.(*DeleteDepartmentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	if err := h.departmentWriteRepo.Delete(ctx, deleteCmd.DepartmentID); err != nil {
		log.Error().Err(err).Str("department_id", deleteCmd.DepartmentID.String()).Msg("failed to delete department")
		return err
	}

	event := &department.DepartmentDeleted{
		DepartmentID: deleteCmd.DepartmentID,
		Timestamp:    time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish DepartmentDeleted event")
		return err
	}

	log.Info().Str("department_id", deleteCmd.DepartmentID.String()).Msg("department deleted successfully")
	return nil
}
