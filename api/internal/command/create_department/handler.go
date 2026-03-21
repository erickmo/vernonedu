package create_department

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/department"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateDepartmentCommand struct {
	Name        string `validate:"required,min=1"`
	Description string
	IsActive    bool
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
	createCmd, ok := cmd.(*CreateDepartmentCommand)
	if !ok {
		return ErrInvalidCommand
	}

	newDepartment, err := department.NewDepartment(createCmd.Name, createCmd.Description, createCmd.IsActive)
	if err != nil {
		log.Error().Err(err).Msg("failed to create department")
		return err
	}

	if err := h.departmentWriteRepo.Save(ctx, newDepartment); err != nil {
		log.Error().Err(err).Msg("failed to save department")
		return err
	}

	event := &department.DepartmentCreated{
		DepartmentID: newDepartment.ID,
		Name:         newDepartment.Name,
		Timestamp:    time.Now().Unix(),
	}

	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish DepartmentCreated event")
		return err
	}

	log.Info().Str("department_id", newDepartment.ID.String()).Msg("department created successfully")
	return nil
}
