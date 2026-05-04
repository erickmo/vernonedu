package list_employees

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
)

type ListEmployeesQuery struct {
	Offset       int
	Limit        int
	Search       string
	DepartmentID string
	Status       string
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

type ListResult struct {
	Data   []*EmployeeReadModel `json:"data"`
	Total  int                  `json:"total"`
	Offset int                  `json:"offset"`
	Limit  int                  `json:"limit"`
}

type Handler struct {
	readRepo hrm.ReadRepository
}

func NewHandler(readRepo hrm.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListEmployeesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	employees, total, err := h.readRepo.ListEmployees(ctx, q.Offset, q.Limit, q.Search, q.DepartmentID, q.Status)
	if err != nil {
		log.Error().Err(err).Msg("failed to list employees")
		return nil, err
	}

	readModels := make([]*EmployeeReadModel, len(employees))
	for i, e := range employees {
		depID := ""
		if e.DepartmentID != nil {
			depID = e.DepartmentID.String()
		}
		contractEnd := ""
		if e.ContractEnd != nil {
			contractEnd = e.ContractEnd.Format("2006-01-02")
		}
		readModels[i] = &EmployeeReadModel{
			ID:             e.ID.String(),
			UserID:         e.UserID.String(),
			EmployeeNumber: e.EmployeeNumber,
			DepartmentID:   depID,
			Position:       e.Position,
			HireDate:       e.HireDate.Format("2006-01-02"),
			Status:         e.Status,
			Phone:          e.Phone,
			Address:        e.Address,
			BaseSalary:     e.BaseSalary,
			BankName:       e.BankName,
			BankAccount:    e.BankAccount,
			ContractType:   e.ContractType,
			ContractEnd:    contractEnd,
			Notes:          e.Notes,
			CreatedAt:      e.CreatedAt.Unix(),
			UpdatedAt:      e.UpdatedAt.Unix(),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
