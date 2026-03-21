package list_journal_entries

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/finance"
)

type JournalEntryReadModel struct {
	ID            uuid.UUID `json:"id"`
	TransactionID uuid.UUID `json:"transaction_id"`
	AccountID     uuid.UUID `json:"account_id"`
	Debit         float64   `json:"debit"`
	Credit        float64   `json:"credit"`
	Description   string    `json:"description"`
	Source        string    `json:"source"`
	CreatedAt     int64     `json:"created_at"`
}

type ListResult struct {
	Data   []*JournalEntryReadModel `json:"data"`
	Total  int                      `json:"total"`
	Offset int                      `json:"offset"`
	Limit  int                      `json:"limit"`
}

type Handler struct {
	readRepo finance.JournalReadRepository
}

func NewHandler(readRepo finance.JournalReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListJournalEntriesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	entries, total, err := h.readRepo.List(ctx, finance.JournalFilter{
		Offset:    q.Offset,
		Limit:     q.Limit,
		Source:    q.Source,
		AccountID: q.AccountID,
		DateFrom:  q.DateFrom,
		DateTo:    q.DateTo,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list journal entries")
		return nil, err
	}

	readModels := make([]*JournalEntryReadModel, len(entries))
	for i, e := range entries {
		readModels[i] = &JournalEntryReadModel{
			ID:            e.ID,
			TransactionID: e.TransactionID,
			AccountID:     e.AccountID,
			Debit:         e.Debit,
			Credit:        e.Credit,
			Description:   e.Description,
			Source:        string(e.Source),
			CreatedAt:     e.CreatedAt.Unix(),
		}
	}

	return &ListResult{Data: readModels, Total: total, Offset: q.Offset, Limit: q.Limit}, nil
}
