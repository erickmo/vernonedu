package get_accounting_stats

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type StatsReadModel struct {
	TotalRevenue float64 `json:"total_revenue"`
	TotalExpense float64 `json:"total_expense"`
	NetProfit    float64 `json:"net_profit"`
	CashAndBank  float64 `json:"cash_and_bank"`
	Receivables  float64 `json:"receivables"`
	Payables     float64 `json:"payables"`
}

type Handler struct {
	readRepo accounting.TransactionReadRepository
}

func NewHandler(readRepo accounting.TransactionReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetAccountingStatsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	stats, err := h.readRepo.GetStats(ctx, q.Month, q.Year)
	if err != nil {
		log.Error().Err(err).Msg("failed to get accounting stats")
		return nil, err
	}

	return &StatsReadModel{
		TotalRevenue: stats.TotalRevenue,
		TotalExpense: stats.TotalExpense,
		NetProfit:    stats.NetProfit,
		CashAndBank:  stats.CashAndBank,
		Receivables:  stats.Receivables,
		Payables:     stats.Payables,
	}, nil
}
