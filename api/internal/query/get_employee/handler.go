package get_employee

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
)

type GetEmployeeQuery struct {
	EmployeeID uuid.UUID
}

type EmployeeReadModel struct {
	ID             string  `json:"id"`
	UserID         string  `json:"user_id"`
	EmployeeNumber string  `json:"employee_number"`
	DepartmentID   string  `json:"department_id"`
	Position       string  `json:"position"`
	HireDate       string  `json:"hire_date"`
	Status         string  `json:"status"`
	Phone          string  `json:"phone"`
	Address        string  `json:"address"`
	BaseSalary     float64 `json:"base_salary"`
	BankName       string  `json:"bank_name"`
	BankAccount    string  `json:"bank_account"`
	ContractType   string  `json:"contract_type"`
	ContractEnd    string  `json:"contract_end"`
	Notes          string  `json:"notes"`
	CreatedAt      int64   `json:"created_at"`
	UpdatedAt      int64   `json:"updated_at"`
}

type Handler struct {
	readRepo hrm.ReadRepository
}

func NewHandler(readRepo hrm.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetEmployeeQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	employee, err := h.readRepo.GetEmployeeByID(ctx, q.EmployeeID)
	if err != nil {
		log.Error().Err(err).Msg("failed to get employee")
		return nil, err
	}

	depID := ""
	if employee.DepartmentID != nil {
		depID = employee.DepartmentID.String()
	}
	contractEnd := ""
	if employee.ContractEnd != nil {
		contractEnd = employee.ContractEnd.Format("2006-01-02")
	}

	return &EmployeeReadModel{
		ID:             employee.ID.String(),
		UserID:         employee.UserID.String(),
		EmployeeNumber: employee.EmployeeNumber,
		DepartmentID:   depID,
		Position:       employee.Position,
		HireDate:       employee.HireDate.Format("2006-01-02"),
		Status:         employee.Status,
		Phone:          employee.Phone,
		Address:        employee.Address,
		BaseSalary:     employee.BaseSalary,
		BankName:       employee.BankName,
		BankAccount:    employee.BankAccount,
		ContractType:   employee.ContractType,
		ContractEnd:    contractEnd,
		Notes:          employee.Notes,
		CreatedAt:      employee.CreatedAt.Unix(),
		UpdatedAt:      employee.UpdatedAt.Unix(),
	}, nil
}
