package list_transactions

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type TransactionReadModel struct {
	ID              uuid.UUID `json:"id"`
	ReferenceNumber string    `json:"reference_number"`
	Description     string    `json:"description"`
	Type            string    `json:"type"`
	Amount          float64   `json:"amount"`
	Category        string    `json:"category"`
	TransactionDate string    `json:"transaction_date"`
	Status          string    `json:"status"`
}

type ListResult struct {
	Data   []*TransactionReadModel `json:"data"`
	Total  int                     `json:"total"`
	Offset int                     `json:"offset"`
	Limit  int                     `json:"limit"`
}

type Handler struct {
	readRepo accounting.TransactionReadRepository
}

func NewHandler(readRepo accounting.TransactionReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListTransactionsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	transactions, total, err := h.readRepo.List(ctx, q.Offset, q.Limit, q.Month, q.Year, q.Type)
	if err != nil {
		log.Error().Err(err).Msg("failed to list transactions")
		return nil, err
	}

	readModels := make([]*TransactionReadModel, len(transactions))
	for i, t := range transactions {
		readModels[i] = &TransactionReadModel{
			ID:              t.ID,
			ReferenceNumber: t.ReferenceNumber,
			Description:     t.Description,
			Type:            t.TransactionType,
			Amount:          t.Amount,
			Category:        t.Category,
			TransactionDate: t.TransactionDate.Format("2006-01-02"),
			Status:          t.Status,
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
