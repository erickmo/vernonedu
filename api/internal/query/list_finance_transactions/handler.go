package list_finance_transactions

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/finance"
)

type TransactionReadModel struct {
	ID              uuid.UUID `json:"id"`
	Code            string    `json:"code"`
	Description     string    `json:"description"`
	AccountDebitID  uuid.UUID `json:"account_debit_id"`
	AccountCreditID uuid.UUID `json:"account_credit_id"`
	Amount          float64   `json:"amount"`
	Reference       string    `json:"reference"`
	BranchID        uuid.UUID `json:"branch_id"`
	Source          string    `json:"source"`
	AttachmentURL   string    `json:"attachment_url"`
	CreatedBy       uuid.UUID `json:"created_by"`
	CreatedAt       int64     `json:"created_at"`
}

type ListResult struct {
	Data   []*TransactionReadModel `json:"data"`
	Total  int                     `json:"total"`
	Offset int                     `json:"offset"`
	Limit  int                     `json:"limit"`
}

type Handler struct {
	readRepo finance.TransactionReadRepository
}

func NewHandler(readRepo finance.TransactionReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListFinanceTransactionsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	txns, total, err := h.readRepo.List(ctx, finance.TransactionFilter{
		Offset:    q.Offset,
		Limit:     q.Limit,
		Source:    q.Source,
		AccountID: q.AccountID,
		BranchID:  q.BranchID,
		DateFrom:  q.DateFrom,
		DateTo:    q.DateTo,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list finance transactions")
		return nil, err
	}

	readModels := make([]*TransactionReadModel, len(txns))
	for i, t := range txns {
		readModels[i] = &TransactionReadModel{
			ID:              t.ID,
			Code:            t.Code,
			Description:     t.Description,
			AccountDebitID:  t.AccountDebitID,
			AccountCreditID: t.AccountCreditID,
			Amount:          t.Amount,
			Reference:       t.Reference,
			BranchID:        t.BranchID,
			Source:          string(t.Source),
			AttachmentURL:   t.AttachmentURL,
			CreatedBy:       t.CreatedBy,
			CreatedAt:       t.CreatedAt.Unix(),
		}
	}

	return &ListResult{Data: readModels, Total: total, Offset: q.Offset, Limit: q.Limit}, nil
}
