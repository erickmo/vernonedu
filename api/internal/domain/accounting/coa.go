package accounting

import (
	"context"
	"sort"
	"time"

	"github.com/google/uuid"
)

type ChartOfAccount struct {
	ID          uuid.UUID
	Code        string
	Name        string
	AccountType string // asset, liability, equity, revenue, expense
	ParentCode  string
	IsActive    bool
	CreatedAt   time.Time
}

// CoaNode is a chart-of-account entry with its child nodes for tree responses.
type CoaNode struct {
	ID          uuid.UUID
	Code        string
	Name        string
	AccountType string
	ParentCode  string
	IsActive    bool
	Children    []*CoaNode
}

// BalanceByAccount holds the running balance for a single COA code.
type BalanceByAccount struct {
	CoaCode      string
	AccountType  string
	BalanceCents int64
}

type CoaReadRepository interface {
	List(ctx context.Context) ([]*ChartOfAccount, error)
}

// CoaBalanceReadRepository fetches running balances for COA codes.
type CoaBalanceReadRepository interface {
	GetBalance(ctx context.Context, coaCode string, branchID *uuid.UUID, dateTo *time.Time) (*BalanceByAccount, error)
}

// BuildTree groups a flat list into a parent/child tree by parent_code or
// derived parent (Indonesian COA convention: 1110 -> 1100 -> 1000).
func BuildTree(accounts []*ChartOfAccount) []*CoaNode {
	if len(accounts) == 0 {
		return nil
	}
	byCode := make(map[string]*CoaNode, len(accounts))
	for _, a := range accounts {
		byCode[a.Code] = &CoaNode{
			ID:          a.ID,
			Code:        a.Code,
			Name:        a.Name,
			AccountType: a.AccountType,
			ParentCode:  a.ParentCode,
			IsActive:    a.IsActive,
		}
	}
	var roots []*CoaNode
	for _, a := range accounts {
		node := byCode[a.Code]
		parentCode := derivedParent(a)
		if parentCode == "" {
			roots = append(roots, node)
			continue
		}
		if parent, ok := byCode[parentCode]; ok {
			parent.Children = append(parent.Children, node)
		} else {
			roots = append(roots, node)
		}
	}
	sortNodes(roots)
	return roots
}

func derivedParent(a *ChartOfAccount) string {
	if a.ParentCode != "" {
		return a.ParentCode
	}
	if len(a.Code) <= 1 {
		return ""
	}
	for i := len(a.Code) - 1; i > 0; i-- {
		if a.Code[i] != '0' {
			candidate := a.Code[:i] + zeros(len(a.Code)-i)
			if candidate != a.Code {
				return candidate
			}
		}
	}
	return ""
}

func zeros(n int) string {
	out := make([]byte, n)
	for i := range out {
		out[i] = '0'
	}
	return string(out)
}

func sortNodes(nodes []*CoaNode) {
	sort.Slice(nodes, func(i, j int) bool { return nodes[i].Code < nodes[j].Code })
	for _, n := range nodes {
		sortNodes(n.Children)
	}
}
