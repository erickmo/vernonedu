package get_finance_account

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/finance"
)

type AccountReadModel struct {
	ID       uuid.UUID  `json:"id"`
	Code     string     `json:"code"`
	Name     string     `json:"name"`
	Type     string     `json:"type"`
	ParentID *uuid.UUID `json:"parent_id"`
	IsActive bool       `json:"is_active"`
	BranchID *uuid.UUID `json:"branch_id"`
}

type Handler struct {
	readRepo finance.AccountReadRepository
}

func NewHandler(readRepo finance.AccountReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetFinanceAccountQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	a, err := h.readRepo.GetByID(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Msg("failed to get finance account")
		return nil, err
	}

	return &AccountReadModel{
		ID:       a.ID,
		Code:     a.Code,
		Name:     a.Name,
		Type:     string(a.Type),
		ParentID: a.ParentID,
		IsActive: a.IsActive,
		BranchID: a.BranchID,
	}, nil
}
