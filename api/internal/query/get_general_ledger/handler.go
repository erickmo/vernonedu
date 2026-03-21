package get_general_ledger

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

// LedgerEntryRM is the read model for one ledger row.
type LedgerEntryRM struct {
	Date           string  `json:"date"`
	ReferenceNo    string  `json:"reference_no"`
	Description    string  `json:"description"`
	Debit          float64 `json:"debit"`
	Credit         float64 `json:"credit"`
	RunningBalance float64 `json:"running_balance"`
}

// GeneralLedgerRM is the response shape.
type GeneralLedgerRM struct {
	AccountCode    string           `json:"account_code"`
	AccountName    string           `json:"account_name"`
	From           string           `json:"from"`
	To             string           `json:"to"`
	BranchID       string           `json:"branch_id,omitempty"`
	OpeningBalance float64          `json:"opening_balance"`
	Entries        []*LedgerEntryRM `json:"entries"`
	TotalDebit     float64          `json:"total_debit"`
	TotalCredit    float64          `json:"total_credit"`
	ClosingBalance float64          `json:"closing_balance"`
}

type Handler struct {
	repo accounting.ReportReadRepository
}

func NewHandler(repo accounting.ReportReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetGeneralLedgerQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}
	if q.AccountCode == "" {
		return nil, ErrMissingAccount
	}

	period, err := parsePeriod(q.From, q.To, q.BranchID)
	if err != nil {
		return nil, err
	}

	gl, err := h.repo.GetGeneralLedger(ctx, q.AccountCode, period)
	if err != nil {
		log.Error().Err(err).Str("account", q.AccountCode).Msg("failed to get general ledger")
		return nil, err
	}

	return toGeneralLedgerRM(gl), nil
}

func toGeneralLedgerRM(gl *accounting.GeneralLedger) *GeneralLedgerRM {
	entries := make([]*LedgerEntryRM, len(gl.Entries))
	for i, e := range gl.Entries {
		entries[i] = &LedgerEntryRM{
			Date:           e.Date.Format("2006-01-02"),
			ReferenceNo:    e.ReferenceNo,
			Description:    e.Description,
			Debit:          e.Debit,
			Credit:         e.Credit,
			RunningBalance: e.RunningBalance,
		}
	}
	return &GeneralLedgerRM{
		AccountCode:    gl.AccountCode,
		AccountName:    gl.AccountName,
		From:           gl.Period.From.Format("2006-01-02"),
		To:             gl.Period.To.Format("2006-01-02"),
		BranchID:       gl.Period.BranchID,
		OpeningBalance: gl.OpeningBalance,
		Entries:        entries,
		TotalDebit:     gl.TotalDebit,
		TotalCredit:    gl.TotalCredit,
		ClosingBalance: gl.ClosingBalance,
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
