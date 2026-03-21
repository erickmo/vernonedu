package get_cash_flow

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

// CashFlowLineRM is the read model for one cash flow line.
type CashFlowLineRM struct {
	Description string  `json:"description"`
	Amount      float64 `json:"amount"`
}

// CashFlowRM is the response shape.
type CashFlowRM struct {
	From           string            `json:"from"`
	To             string            `json:"to"`
	BranchID       string            `json:"branch_id,omitempty"`
	Operating      []*CashFlowLineRM `json:"operating"`
	Investing      []*CashFlowLineRM `json:"investing"`
	Financing      []*CashFlowLineRM `json:"financing"`
	NetOperating   float64           `json:"net_operating"`
	NetInvesting   float64           `json:"net_investing"`
	NetFinancing   float64           `json:"net_financing"`
	OpeningBalance float64           `json:"opening_balance"`
	NetChange      float64           `json:"net_change"`
	ClosingBalance float64           `json:"closing_balance"`
}

type Handler struct {
	repo accounting.ReportReadRepository
}

func NewHandler(repo accounting.ReportReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetCashFlowQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	period, err := parsePeriod(q.From, q.To, q.BranchID)
	if err != nil {
		return nil, err
	}

	cf, err := h.repo.GetCashFlow(ctx, period)
	if err != nil {
		log.Error().Err(err).Msg("failed to get cash flow")
		return nil, err
	}

	return toCashFlowRM(cf), nil
}

func toCFLines(lines []*accounting.CashFlowLine) []*CashFlowLineRM {
	out := make([]*CashFlowLineRM, len(lines))
	for i, l := range lines {
		out[i] = &CashFlowLineRM{Description: l.Description, Amount: l.Amount}
	}
	return out
}

func toCashFlowRM(cf *accounting.CashFlow) *CashFlowRM {
	return &CashFlowRM{
		From:           cf.Period.From.Format("2006-01-02"),
		To:             cf.Period.To.Format("2006-01-02"),
		BranchID:       cf.Period.BranchID,
		Operating:      toCFLines(cf.Operating),
		Investing:      toCFLines(cf.Investing),
		Financing:      toCFLines(cf.Financing),
		NetOperating:   cf.NetOperating,
		NetInvesting:   cf.NetInvesting,
		NetFinancing:   cf.NetFinancing,
		OpeningBalance: cf.OpeningBalance,
		NetChange:      cf.NetChange,
		ClosingBalance: cf.ClosingBalance,
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
