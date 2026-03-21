package get_trial_balance

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

// TrialBalanceLineRM is the read model for one trial balance row.
type TrialBalanceLineRM struct {
	AccountCode string  `json:"account_code"`
	AccountName string  `json:"account_name"`
	AccountType string  `json:"account_type"`
	Debit       float64 `json:"debit"`
	Credit      float64 `json:"credit"`
}

// TrialBalanceRM is the response shape.
type TrialBalanceRM struct {
	From        string                `json:"from"`
	To          string                `json:"to"`
	BranchID    string                `json:"branch_id,omitempty"`
	Lines       []*TrialBalanceLineRM `json:"lines"`
	TotalDebit  float64               `json:"total_debit"`
	TotalCredit float64               `json:"total_credit"`
	IsBalanced  bool                  `json:"is_balanced"`
}

type Handler struct {
	repo accounting.ReportReadRepository
}

func NewHandler(repo accounting.ReportReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetTrialBalanceQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	period, err := parsePeriod(q.From, q.To, q.BranchID)
	if err != nil {
		return nil, err
	}

	tb, err := h.repo.GetTrialBalance(ctx, period)
	if err != nil {
		log.Error().Err(err).Msg("failed to get trial balance")
		return nil, err
	}

	return toTrialBalanceRM(tb), nil
}

func toTrialBalanceRM(tb *accounting.TrialBalance) *TrialBalanceRM {
	lines := make([]*TrialBalanceLineRM, len(tb.Lines))
	for i, l := range tb.Lines {
		lines[i] = &TrialBalanceLineRM{
			AccountCode: l.AccountCode,
			AccountName: l.AccountName,
			AccountType: l.AccountType,
			Debit:       l.Debit,
			Credit:      l.Credit,
		}
	}
	return &TrialBalanceRM{
		From:        tb.Period.From.Format("2006-01-02"),
		To:          tb.Period.To.Format("2006-01-02"),
		BranchID:    tb.Period.BranchID,
		Lines:       lines,
		TotalDebit:  tb.TotalDebit,
		TotalCredit: tb.TotalCredit,
		IsBalanced:  tb.IsBalanced,
	}
}

func parsePeriod(from, to, branchID string) (accounting.ReportPeriod, error) {
	now := time.Now()
	defaultFrom := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	defaultTo := now

	var f, t time.Time
	var err error

	if from == "" {
		f = defaultFrom
	} else if f, err = time.Parse("2006-01-02", from); err != nil {
		return accounting.ReportPeriod{}, err
	}

	if to == "" {
		t = defaultTo
	} else if t, err = time.Parse("2006-01-02", to); err != nil {
		return accounting.ReportPeriod{}, err
	}

	return accounting.ReportPeriod{From: f, To: t, BranchID: branchID}, nil
}
