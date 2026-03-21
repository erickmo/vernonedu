package get_cash_forecast

import (
	"context"

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
	q, ok := query.(*GetCashForecastQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	months := q.Months
	if months <= 0 {
		months = 3
	}

	result, err := h.repo.GetCashForecast(ctx, months, q.BranchID)
	if err != nil {
		log.Error().Err(err).Msg("failed to get cash forecast")
		return nil, err
	}
	return result, nil
}
