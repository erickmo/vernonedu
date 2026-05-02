package get_bank_account

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	listba "github.com/vernonedu/entrepreneurship-api/internal/query/list_bank_accounts"
)

type Handler struct {
	readRepo accounting.BankAccountReadRepository
}

func NewHandler(readRepo accounting.BankAccountReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetBankAccountQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	b, err := h.readRepo.Get(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("id", q.ID.String()).Msg("failed to get bank account")
		return nil, err
	}
	return &listba.BankAccountView{
		ID:            b.ID.String(),
		BranchID:      b.BranchID.String(),
		Name:          b.Name,
		AccountNumber: b.AccountNumber,
		BankName:      b.BankName,
		BalanceCents:  b.BalanceCents,
		Currency:      b.Currency,
		CoaCode:       b.CoaCode,
		IsActive:      b.IsActive,
	}, nil
}
