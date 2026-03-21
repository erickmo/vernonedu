package get_invoice_stats

import (
	"context"
	"errors"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

var ErrInvalidQuery = errors.New("invalid get invoice stats query type")

type Handler struct {
	readRepo accounting.InvoiceReadRepository
}

func NewHandler(readRepo accounting.InvoiceReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetInvoiceStatsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	stats, err := h.readRepo.GetStats(ctx, q.BranchID)
	if err != nil {
		log.Error().Err(err).Msg("failed to get invoice stats")
		return nil, err
	}

	return stats, nil
}
