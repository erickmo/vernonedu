package get_financial_ratios

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type Handler struct {
	repo accounting.AnalysisReadRepository
}

func NewHandler(repo accounting.AnalysisReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetFinancialRatiosQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	now := time.Now()
	params := buildPeriodParams(q, now)

	result, err := h.repo.GetFinancialRatios(ctx, params)
	if err != nil {
		log.Error().Err(err).Msg("failed to get financial ratios")
		return nil, err
	}
	return result, nil
}

// buildPeriodParams computes PeriodParams from query fields, applying defaults for zero values.
func buildPeriodParams(q *GetFinancialRatiosQuery, now time.Time) accounting.PeriodParams {
	month := q.Month
	year := q.Year
	if month == 0 {
		month = int(now.Month())
	}
	if year == 0 {
		year = now.Year()
	}
	period := q.Period
	if period == "" {
		period = "monthly"
	}
	comparison := q.Comparison
	if comparison == "" {
		comparison = "prev_month"
	}
	return accounting.PeriodParams{
		Period:     period,
		Month:      month,
		Year:       year,
		BranchID:   q.BranchID,
		Comparison: comparison,
	}
}
