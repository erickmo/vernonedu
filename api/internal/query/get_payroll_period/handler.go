package get_payroll_period

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
)

type GetPayrollPeriodQuery struct {
	PeriodID uuid.UUID
}

type PayrollPeriodReadModel struct {
	ID          string `json:"id"`
	Period      string `json:"period"`
	StartDate   string `json:"start_date"`
	EndDate     string `json:"end_date"`
	Status      string `json:"status"`
	ApprovedBy  string `json:"approved_by"`
	ApprovedAt  int64  `json:"approved_at"`
	DisbursedAt int64  `json:"disbursed_at"`
	Notes       string `json:"notes"`
	CreatedAt   int64  `json:"created_at"`
	UpdatedAt   int64  `json:"updated_at"`
}

type Handler struct {
	readRepo hrm.ReadRepository
}

func NewHandler(readRepo hrm.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetPayrollPeriodQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	pp, err := h.readRepo.GetPayrollPeriodByID(ctx, q.PeriodID)
	if err != nil {
		log.Error().Err(err).Msg("failed to get payroll period")
		return nil, err
	}

	approvedBy := ""
	if pp.ApprovedBy != nil {
		approvedBy = pp.ApprovedBy.String()
	}
	var approvedAt, disbursedAt int64
	if pp.ApprovedAt != nil {
		approvedAt = pp.ApprovedAt.Unix()
	}
	if pp.DisbursedAt != nil {
		disbursedAt = pp.DisbursedAt.Unix()
	}

	return &PayrollPeriodReadModel{
		ID:          pp.ID.String(),
		Period:      pp.Period,
		StartDate:   pp.StartDate.Format("2006-01-02"),
		EndDate:     pp.EndDate.Format("2006-01-02"),
		Status:      pp.Status,
		ApprovedBy:  approvedBy,
		ApprovedAt:  approvedAt,
		DisbursedAt: disbursedAt,
		Notes:       pp.Notes,
		CreatedAt:   pp.CreatedAt.Unix(),
		UpdatedAt:   pp.UpdatedAt.Unix(),
	}, nil
}
