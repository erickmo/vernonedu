package get_revenue_analysis

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
	q, ok := query.(*GetRevenueAnalysisQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	now := time.Now()
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
	groupBy := q.GroupBy
	if groupBy == "" {
		groupBy = "course_type"
	}

	params := accounting.PeriodParams{
		Period:   period,
		Month:    month,
		Year:     year,
		BranchID: q.BranchID,
	}

	result, err := h.repo.GetRevenueAnalysis(ctx, params, groupBy)
	if err != nil {
		log.Error().Err(err).Msg("failed to get revenue analysis")
		return nil, err
	}
	return result, nil
}
