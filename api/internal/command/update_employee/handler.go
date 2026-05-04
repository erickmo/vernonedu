package update_employee

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type UpdateEmployeeCommand struct {
	ID           string  `validate:"required"`
	DepartmentID *string `validate:"omitempty"`
	Position     string  `validate:"required,min=1"`
	Status       string  `validate:"required"`
	Phone        string
	Address      string
	BaseSalary   float64
	BankName     string
	BankAccount  string
	ContractType string
	ContractEnd  *string
	Notes        string
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
	c, ok := cmd.(*UpdateEmployeeCommand)
	if !ok {
		return ErrInvalidCommand
	}

	id, err := uuid.Parse(c.ID)
	if err != nil {
		return ErrInvalidCommand
	}

	employee, err := h.readRepo.GetEmployeeByID(ctx, id)
	if err != nil {
		log.Error().Err(err).Msg("failed to get employee")
		return err
	}

	employee.Position = c.Position
	employee.Status = c.Status
	employee.Phone = c.Phone
	employee.Address = c.Address
	employee.BaseSalary = c.BaseSalary
	employee.BankName = c.BankName
	employee.BankAccount = c.BankAccount
	employee.ContractType = c.ContractType
	employee.Notes = c.Notes

	if c.DepartmentID != nil {
		depID, parseErr := uuid.Parse(*c.DepartmentID)
		if parseErr == nil {
			employee.DepartmentID = &depID
		}
	} else {
		employee.DepartmentID = nil
	}

	if c.ContractEnd != nil {
		ce, parseErr := time.Parse("2006-01-02", *c.ContractEnd)
		if parseErr == nil {
			employee.ContractEnd = &ce
		}
	}

	employee.UpdatedAt = time.Now()

	if err := h.writeRepo.UpdateEmployee(ctx, employee); err != nil {
		log.Error().Err(err).Msg("failed to update employee")
		return err
	}

	log.Info().Str("employee_id", id.String()).Msg("employee updated successfully")
	return nil
}
