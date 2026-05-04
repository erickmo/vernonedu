package list_payroll_periods

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/hrm"
)

type ListPayrollPeriodsQuery struct {
	Status string
	Offset int
	Limit  int
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

type ListResult struct {
	Data   []*PayrollPeriodReadModel `json:"data"`
	Total  int                       `json:"total"`
	Offset int                       `json:"offset"`
	Limit  int                       `json:"limit"`
}

type Handler struct {
	readRepo hrm.ReadRepository
}

func NewHandler(readRepo hrm.ReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListPayrollPeriodsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	periods, total, err := h.readRepo.ListPayrollPeriods(ctx, q.Status, q.Offset, q.Limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to list payroll periods")
		return nil, err
	}

	readModels := make([]*PayrollPeriodReadModel, len(periods))
	for i, pp := range periods {
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
		readModels[i] = &PayrollPeriodReadModel{
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
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
