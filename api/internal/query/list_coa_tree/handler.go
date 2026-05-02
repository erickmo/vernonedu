package list_coa_tree

import (
	"context"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

// CoaNodeView is the JSON projection of accounting.CoaNode.
type CoaNodeView struct {
	ID          string         `json:"id"`
	Code        string         `json:"code"`
	Name        string         `json:"name"`
	AccountType string         `json:"account_type"`
	ParentCode  string         `json:"parent_code"`
	IsActive    bool           `json:"is_active"`
	Children    []*CoaNodeView `json:"children,omitempty"`
}

type Handler struct {
	readRepo accounting.CoaReadRepository
}

func NewHandler(readRepo accounting.CoaReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	if _, ok := query.(*ListCoaTreeQuery); !ok {
		return nil, ErrInvalidQuery
	}
	flat, err := h.readRepo.List(ctx)
	if err != nil {
		log.Error().Err(err).Msg("failed to list coa for tree")
		return nil, err
	}
	tree := accounting.BuildTree(flat)
	out := make([]*CoaNodeView, len(tree))
	for i, n := range tree {
		out[i] = toView(n)
	}
	return out, nil
}

func toView(n *accounting.CoaNode) *CoaNodeView {
	v := &CoaNodeView{
		ID:          n.ID.String(),
		Code:        n.Code,
		Name:        n.Name,
		AccountType: n.AccountType,
		ParentCode:  n.ParentCode,
		IsActive:    n.IsActive,
	}
	if len(n.Children) > 0 {
		v.Children = make([]*CoaNodeView, len(n.Children))
		for i, c := range n.Children {
			v.Children[i] = toView(c)
		}
	}
	return v
}
