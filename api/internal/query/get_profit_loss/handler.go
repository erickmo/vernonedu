package get_profit_loss

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

// PLLineRM is the read model for one P&L line.
type PLLineRM struct {
	AccountCode string  `json:"account_code"`
	AccountName string  `json:"account_name"`
	ParentCode  string  `json:"parent_code"`
	Amount      float64 `json:"amount"`
}

// ProfitLossRM is the response shape.
type ProfitLossRM struct {
	From           string      `json:"from"`
	To             string      `json:"to"`
	BranchID       string      `json:"branch_id,omitempty"`
	Revenue        []*PLLineRM `json:"revenue"`
	HPP            []*PLLineRM `json:"hpp"`
	OpExpenses     []*PLLineRM `json:"op_expenses"`
	TotalRevenue   float64     `json:"total_revenue"`
	TotalHPP       float64     `json:"total_hpp"`
	GrossProfit    float64     `json:"gross_profit"`
	TotalOpExpense float64     `json:"total_op_expense"`
	NetProfit      float64     `json:"net_profit"`
}

type Handler struct {
	repo accounting.ReportReadRepository
}

func NewHandler(repo accounting.ReportReadRepository) *Handler {
	return &Handler{repo: repo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetProfitLossQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	period, err := parsePeriod(q.From, q.To, q.BranchID)
	if err != nil {
		return nil, err
	}

	pl, err := h.repo.GetProfitLoss(ctx, period)
	if err != nil {
		log.Error().Err(err).Msg("failed to get profit loss")
		return nil, err
	}

	return toProfitLossRM(pl), nil
}

func toPlLineRMs(lines []*accounting.PLLine) []*PLLineRM {
	out := make([]*PLLineRM, len(lines))
	for i, l := range lines {
		out[i] = &PLLineRM{
			AccountCode: l.AccountCode,
			AccountName: l.AccountName,
			ParentCode:  l.ParentCode,
			Amount:      l.Amount,
		}
	}
	return out
}

func toProfitLossRM(pl *accounting.ProfitLoss) *ProfitLossRM {
	return &ProfitLossRM{
		From:           pl.Period.From.Format("2006-01-02"),
		To:             pl.Period.To.Format("2006-01-02"),
		BranchID:       pl.Period.BranchID,
		Revenue:        toPlLineRMs(pl.Revenue),
		HPP:            toPlLineRMs(pl.HPP),
		OpExpenses:     toPlLineRMs(pl.OpExpenses),
		TotalRevenue:   pl.TotalRevenue,
		TotalHPP:       pl.TotalHPP,
		GrossProfit:    pl.GrossProfit,
		TotalOpExpense: pl.TotalOpExpense,
		NetProfit:      pl.NetProfit,
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
