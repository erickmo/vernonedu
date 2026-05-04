package create_employee

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type CreateEmployeeCommand struct {
	UserID         string  `validate:"required"`
	EmployeeNumber string  `validate:"required,min=1"`
	DepartmentID   *string `validate:"omitempty"`
	Position       string  `validate:"required,min=1"`
	HireDate       string  `validate:"required"`
	Phone          string
	Address        string
	BaseSalary     float64
	BankName       string
	BankAccount    string
	ContractType   string
	ContractEnd    *string
	Notes          string
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
	c, ok := cmd.(*CreateEmployeeCommand)
	if !ok {
		return ErrInvalidCommand
	}

	userID, err := uuid.Parse(c.UserID)
	if err != nil {
		return ErrInvalidCommand
	}

	hireDate, err := time.Parse("2006-01-02", c.HireDate)
	if err != nil {
		return ErrInvalidCommand
	}

	employee, err := hrm.NewEmployee(userID, c.EmployeeNumber, c.Position, hireDate)
	if err != nil {
		log.Error().Err(err).Msg("failed to create employee entity")
		return err
	}

	if c.DepartmentID != nil {
		depID, err := uuid.Parse(*c.DepartmentID)
		if err == nil {
			employee.DepartmentID = &depID
		}
	}
	employee.Phone = c.Phone
	employee.Address = c.Address
	employee.BaseSalary = c.BaseSalary
	employee.BankName = c.BankName
	employee.BankAccount = c.BankAccount
	employee.ContractType = c.ContractType
	employee.Notes = c.Notes

	if c.ContractEnd != nil {
		ce, err := time.Parse("2006-01-02", *c.ContractEnd)
		if err == nil {
			employee.ContractEnd = &ce
		}
	}

	if err := h.writeRepo.SaveEmployee(ctx, employee); err != nil {
		log.Error().Err(err).Msg("failed to save employee")
		return err
	}

	log.Info().Str("employee_id", employee.ID.String()).Msg("employee created successfully")
	return nil
}
