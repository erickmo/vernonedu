package get_budget_vs_actual

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type BudgetItemReadModel struct {
	Category     string  `json:"category"`
	IsPendapatan bool    `json:"is_pendapatan"`
	Anggaran     float64 `json:"anggaran"`
	Realisasi    float64 `json:"realisasi"`
}

type Handler struct {
	readRepo accounting.TransactionReadRepository
}

func NewHandler(readRepo accounting.TransactionReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetBudgetVsActualQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	items, err := h.readRepo.GetBudgetVsActual(ctx, q.Month, q.Year)
	if err != nil {
		log.Error().Err(err).Msg("failed to get budget vs actual")
		return nil, err
	}

	readModels := make([]*BudgetItemReadModel, len(items))
	for i, item := range items {
		readModels[i] = &BudgetItemReadModel{
			Category:     item.Category,
			IsPendapatan: item.IsPendapatan,
			Anggaran:     item.Anggaran,
			Realisasi:    item.Realisasi,
		}
	}

	return readModels, nil
}
