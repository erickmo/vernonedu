package get_batch_profitability

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
	q, ok := query.(*GetBatchProfitabilityQuery)
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
	sort := q.Sort
	if sort == "" {
		sort = "top"
	}
	limit := q.Limit
	if limit <= 0 {
		limit = 10
	}

	params := accounting.PeriodParams{
		Period:   period,
		Month:    month,
		Year:     year,
		BranchID: q.BranchID,
	}

	result, err := h.repo.GetBatchProfitability(ctx, params, sort, limit)
	if err != nil {
		log.Error().Err(err).Msg("failed to get batch profitability")
		return nil, err
	}
	return result, nil
}
