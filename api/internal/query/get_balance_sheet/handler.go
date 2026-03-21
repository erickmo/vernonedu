package get_balance_sheet

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

// BalanceSheetLineRM is the read model for one balance sheet line.
type BalanceSheetLineRM struct {
	AccountCode string  `json:"account_code"`
	AccountName string  `json:"account_name"`
	AccountType string  `json:"account_type"`
	ParentCode  string  `json:"parent_code"`
	Balance     float64 `json:"balance"`
}

// BalanceSheetRM is the response shape.
type BalanceSheetRM struct {
	From        string               `json:"from"`
	To          string               `json:"to"`
	BranchID    string               `json:"branch_id,omitempty"`
	Assets      []*BalanceSheetLineRM `json:"assets"`
	Liabilities []*BalanceSheetLineRM `json:"liabilities"`
	Equity      []*BalanceSheetLineRM `json:"equity"`
	TotalAssets float64              `json:"total_assets"`
	TotalLiab   float64              `json:"total_liabilities"`
	TotalEquity float64              `json:"total_equity"`
	IsBalanced  bool                 `json:"is_balanced"`
}

type Handler struct {
	repo accounting.ReportReadRepository
}

func NewHandler(repo accounting.ReportReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetBalanceSheetQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	period, err := parsePeriod(q.From, q.To, q.BranchID)
	if err != nil {
		return nil, err
	}

	bs, err := h.repo.GetBalanceSheet(ctx, period)
	if err != nil {
		log.Error().Err(err).Msg("failed to get balance sheet")
		return nil, err
	}

	return toBalanceSheetRM(bs), nil
}

func toLineRM(lines []*accounting.BalanceSheetLine) []*BalanceSheetLineRM {
	out := make([]*BalanceSheetLineRM, len(lines))
	for i, l := range lines {
		out[i] = &BalanceSheetLineRM{
			AccountCode: l.AccountCode,
			AccountName: l.AccountName,
			AccountType: l.AccountType,
			ParentCode:  l.ParentCode,
			Balance:     l.Balance,
		}
	}
	return out
}

func toBalanceSheetRM(bs *accounting.BalanceSheet) *BalanceSheetRM {
	return &BalanceSheetRM{
		From:        bs.Period.From.Format("2006-01-02"),
		To:          bs.Period.To.Format("2006-01-02"),
		BranchID:    bs.Period.BranchID,
		Assets:      toLineRM(bs.Assets),
		Liabilities: toLineRM(bs.Liabilities),
		Equity:      toLineRM(bs.Equity),
		TotalAssets: bs.TotalAssets,
		TotalLiab:   bs.TotalLiab,
		TotalEquity: bs.TotalEquity,
		IsBalanced:  bs.IsBalanced,
	}
}

// parsePeriod converts from/to strings to ReportPeriod.
// Defaults to current month if strings are empty.
func parsePeriod(from, to, branchID string) (accounting.ReportPeriod, error) {
	now := time.Now()
	defaultFrom := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	defaultTo := now

	var f, t time.Time
	var err error

	if from == "" {
		f = defaultFrom
	} else {
		f, err = time.Parse("2006-01-02", from)
		if err != nil {
			return accounting.ReportPeriod{}, err
		}
	}

	if to == "" {
		t = defaultTo
	} else {
		t, err = time.Parse("2006-01-02", to)
		if err != nil {
			return accounting.ReportPeriod{}, err
		}
	}

	return accounting.ReportPeriod{From: f, To: t, BranchID: branchID}, nil
}
