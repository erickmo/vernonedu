package get_financial_suggestions

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
	_, ok := query.(*GetFinancialSuggestionsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	result, err := h.repo.GetSuggestions(ctx)
	if err != nil {
		log.Error().Err(err).Msg("failed to get financial suggestions")
		return nil, err
	}
	return result, nil
}
