package list_coa

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type CoaReadModel struct {
	ID          string `json:"id"`
	Code        string `json:"code"`
	Name        string `json:"name"`
	AccountType string `json:"account_type"`
	ParentCode  string `json:"parent_code"`
	IsActive    bool   `json:"is_active"`
}

type Handler struct {
	readRepo accounting.CoaReadRepository
}

func NewHandler(readRepo accounting.CoaReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	_, ok := query.(*ListCoaQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	coas, err := h.readRepo.List(ctx)
	if err != nil {
		log.Error().Err(err).Msg("failed to list chart of accounts")
		return nil, err
	}

	readModels := make([]*CoaReadModel, len(coas))
	for i, c := range coas {
		readModels[i] = &CoaReadModel{
			ID:          c.ID.String(),
			Code:        c.Code,
			Name:        c.Name,
			AccountType: c.AccountType,
			ParentCode:  c.ParentCode,
			IsActive:    c.IsActive,
		}
	}

	return readModels, nil
}
