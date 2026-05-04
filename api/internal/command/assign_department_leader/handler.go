package assign_department_leader

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

type AssignDepartmentLeaderCommand struct {
	DepartmentID uuid.UUID  `validate:"required"`
	LeaderID     *uuid.UUID `validate:"required"`
}

type Handler struct {
	departmentReadRepo  department.ReadRepository
	departmentWriteRepo department.WriteRepository
	eventBus            eventbus.EventBus
}

func NewHandler(
	departmentReadRepo department.ReadRepository,
	departmentWriteRepo department.WriteRepository,
	eventBus eventbus.EventBus,
) *Handler {
	return &Handler{
		departmentReadRepo:  departmentReadRepo,
		departmentWriteRepo: departmentWriteRepo,
		eventBus:            eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	assignCmd, ok := cmd.(*AssignDepartmentLeaderCommand)
	if !ok {
		return ErrInvalidCommand
	}

	dept, err := h.departmentReadRepo.GetByID(ctx, assignCmd.DepartmentID)
	if err != nil {
		if errors.Is(err, department.ErrDepartmentNotFound) {
			return department.ErrDepartmentNotFound
		}
		log.Error().Err(err).Str("department_id", assignCmd.DepartmentID.String()).Msg("failed to get department")
		return err
	}

	dept.LeaderID = assignCmd.LeaderID
	dept.UpdatedAt = time.Now()

	if err := h.departmentWriteRepo.Update(ctx, dept); err != nil {
		log.Error().Err(err).Msg("failed to update department leader")
		return err
	}

	log.Info().
		Str("department_id", dept.ID.String()).
		Str("leader_id", assignCmd.LeaderID.String()).
		Msg("department leader assigned")

	return nil
}
