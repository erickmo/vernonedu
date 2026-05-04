package list_payroll_items

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
)

type ListPayrollItemsQuery struct {
	PayrollPeriodID string `validate:"required"`
}

type PayrollItemReadModel struct {
	ID                  string  `json:"id"`
	PayrollPeriodID     string  `json:"payroll_period_id"`
	EmployeeID          string  `json:"employee_id"`
	BaseSalary          float64 `json:"base_salary"`
	FacilitatorSessions int     `json:"facilitator_sessions"`
	FacilitatorFee      float64 `json:"facilitator_fee"`
	AttendanceDeduction float64 `json:"attendance_deduction"`
	Bonus               float64 `json:"bonus"`
	TotalAmount         float64 `json:"total_amount"`
	Status              string  `json:"status"`
	Notes               string  `json:"notes"`
	CreatedAt           int64   `json:"created_at"`
	UpdatedAt           int64   `json:"updated_at"`
}

type Handler struct {
	readRepo hrm.ReadRepository
}

func NewHandler(readRepo hrm.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListPayrollItemsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	periodID, err := uuid.Parse(q.PayrollPeriodID)
	if err != nil {
		return nil, ErrInvalidQuery
	}

	items, err := h.readRepo.GetPayrollItemsByPeriod(ctx, periodID)
	if err != nil {
		log.Error().Err(err).Msg("failed to list payroll items")
		return nil, err
	}

	readModels := make([]*PayrollItemReadModel, len(items))
	for i, pi := range items {
		readModels[i] = &PayrollItemReadModel{
			ID:                  pi.ID.String(),
			PayrollPeriodID:     pi.PayrollPeriodID.String(),
			EmployeeID:          pi.EmployeeID.String(),
			BaseSalary:          pi.BaseSalary,
			FacilitatorSessions: pi.FacilitatorSessions,
			FacilitatorFee:      pi.FacilitatorFee,
			AttendanceDeduction: pi.AttendanceDeduction,
			Bonus:               pi.Bonus,
			TotalAmount:         pi.TotalAmount,
			Status:              pi.Status,
			Notes:               pi.Notes,
			CreatedAt:           pi.CreatedAt.Unix(),
			UpdatedAt:           pi.UpdatedAt.Unix(),
		}
	}

	return readModels, nil
}
