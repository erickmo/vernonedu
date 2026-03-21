package list_finance_accounts

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/finance"
)

// AccountNode is the tree node for CoA
type AccountNode struct {
	ID       uuid.UUID      `json:"id"`
	Code     string         `json:"code"`
	Name     string         `json:"name"`
	Type     string         `json:"type"`
	ParentID *uuid.UUID     `json:"parent_id"`
	IsActive bool           `json:"is_active"`
	BranchID *uuid.UUID     `json:"branch_id"`
	Children []*AccountNode `json:"children"`
}

type Handler struct {
	readRepo finance.AccountReadRepository
}

func NewHandler(readRepo finance.AccountReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListFinanceAccountsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	accounts, err := h.readRepo.ListAll(ctx, q.BranchID)
	if err != nil {
		log.Error().Err(err).Msg("failed to list finance accounts")
		return nil, err
	}

	return buildTree(accounts), nil
}

func buildTree(accounts []*finance.ChartOfAccount) []*AccountNode {
	nodeMap := make(map[uuid.UUID]*AccountNode)
	for _, a := range accounts {
		nodeMap[a.ID] = &AccountNode{
			ID:       a.ID,
			Code:     a.Code,
			Name:     a.Name,
			Type:     string(a.Type),
			ParentID: a.ParentID,
			IsActive: a.IsActive,
			BranchID: a.BranchID,
			Children: []*AccountNode{},
		}
	}

	var roots []*AccountNode
	for _, a := range accounts {
		node := nodeMap[a.ID]
		if a.ParentID == nil {
			roots = append(roots, node)
		} else if parent, ok := nodeMap[*a.ParentID]; ok {
			parent.Children = append(parent.Children, node)
		} else {
			roots = append(roots, node)
		}
	}
	return roots
}
