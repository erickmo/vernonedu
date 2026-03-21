package update_department

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type UpdateDepartmentCommand struct {
	DepartmentID uuid.UUID `validate:"required"`
	Name         string    `validate:"required,min=1"`
	Description  string
	IsActive     bool
}

type Handler struct {
	departmentReadRepo  department.ReadRepository
	departmentWriteRepo department.WriteRepository
	eventBus            eventbus.EventBus
}

func NewHandler(departmentReadRepo department.ReadRepository, departmentWriteRepo department.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		departmentReadRepo:  departmentReadRepo,
		departmentWriteRepo: departmentWriteRepo,
		eventBus:            eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	updateCmd, ok := cmd.(*UpdateDepartmentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	existingDepartment, err := h.departmentReadRepo.GetByID(ctx, updateCmd.DepartmentID)
	if err != nil {
		if errors.Is(err, department.ErrDepartmentNotFound) {
			return department.ErrDepartmentNotFound
		}
		log.Error().Err(err).Str("department_id", updateCmd.DepartmentID.String()).Msg("failed to get department")
		return err
	}

	if err := existingDepartment.UpdateName(updateCmd.Name); err != nil {
		log.Error().Err(err).Msg("failed to update department name")
		return err
	}
	existingDepartment.Description = updateCmd.Description
	existingDepartment.IsActive = updateCmd.IsActive

	if err := h.departmentWriteRepo.Update(ctx, existingDepartment); err != nil {
		log.Error().Err(err).Msg("failed to update department")
		return err
	}

	event := &department.DepartmentUpdated{
		DepartmentID: existingDepartment.ID,
		Timestamp:    time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish DepartmentUpdated event")
		return err
	}

	log.Info().Str("department_id", existingDepartment.ID.String()).Msg("department updated successfully")
	return nil
}
