package get_balance_by_account

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type BalanceView struct {
	CoaCode      string `json:"coa_code"`
	AccountType  string `json:"account_type"`
	BalanceCents int64  `json:"balance_cents"`
}

type Handler struct {
	readRepo accounting.CoaBalanceReadRepository
}

func NewHandler(readRepo accounting.CoaBalanceReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetBalanceByAccountQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	if q.CoaCode == "" {
		return nil, ErrInvalidQuery
	}
	bal, err := h.readRepo.GetBalance(ctx, q.CoaCode, q.BranchID, q.DateTo)
	if err != nil {
		log.Error().Err(err).Str("code", q.CoaCode).Msg("failed to get balance")
		return nil, err
	}
	return &BalanceView{
		CoaCode:      bal.CoaCode,
		AccountType:  bal.AccountType,
		BalanceCents: bal.BalanceCents,
	}, nil
}
