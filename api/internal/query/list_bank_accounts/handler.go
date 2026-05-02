package list_bank_accounts

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type BankAccountView struct {
	ID            string `json:"id"`
	BranchID      string `json:"branch_id"`
	Name          string `json:"name"`
	AccountNumber string `json:"account_number"`
	BankName      string `json:"bank_name"`
	BalanceCents  int64  `json:"balance_cents"`
	Currency      string `json:"currency"`
	CoaCode       string `json:"coa_code,omitempty"`
	IsActive      bool   `json:"is_active"`
}

type Handler struct {
	readRepo accounting.BankAccountReadRepository
}

func NewHandler(readRepo accounting.BankAccountReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListBankAccountsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	rows, err := h.readRepo.List(ctx, q.BranchID, q.IncludeInactive)
	if err != nil {
		log.Error().Err(err).Msg("failed to list bank accounts")
		return nil, err
	}
	out := make([]*BankAccountView, len(rows))
	for i, b := range rows {
		out[i] = &BankAccountView{
			ID:            b.ID.String(),
			BranchID:      b.BranchID.String(),
			Name:          b.Name,
			AccountNumber: b.AccountNumber,
			BankName:      b.BankName,
			BalanceCents:  b.BalanceCents,
			Currency:      b.Currency,
			CoaCode:       b.CoaCode,
			IsActive:      b.IsActive,
		}
	}
	return out, nil
}
