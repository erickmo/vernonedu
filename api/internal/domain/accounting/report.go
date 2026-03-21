package accounting

import (
	"context"
	"time"
)

// ReportPeriod carries the date range for all report queries.
type ReportPeriod struct {
	From     time.Time
	To       time.Time
	BranchID string // empty = all branches (consolidated, director-only)
}

// ─── Balance Sheet ─────────────────────────────────────────────────────────────

// BalanceSheetLine is one account row in the balance sheet.
type BalanceSheetLine struct {
	AccountCode string
	AccountName string
	AccountType string // "asset" | "liability" | "equity"
	ParentCode  string
	Balance     float64
}

// BalanceSheet groups assets vs liabilities+equity.
type BalanceSheet struct {
	Period      ReportPeriod
	Assets      []*BalanceSheetLine
	Liabilities []*BalanceSheetLine
	Equity      []*BalanceSheetLine
	TotalAssets float64
	TotalLiab   float64
	TotalEquity float64
	IsBalanced  bool // TotalAssets == TotalLiab + TotalEquity
}

// ─── Profit & Loss ─────────────────────────────────────────────────────────────

// PLLine is one account row in the P&L statement.
type PLLine struct {
	AccountCode string
	AccountName string
	ParentCode  string
	Amount      float64 // positive = revenue or expense amount
}

// ProfitLoss is the income statement.
type ProfitLoss struct {
	Period         ReportPeriod
	Revenue        []*PLLine
	HPP            []*PLLine // Harga Pokok Pendapatan (COGS) — expense 5100
	OpExpenses     []*PLLine // Beban Operasional — expense 5200+
	TotalRevenue   float64
	TotalHPP       float64
	GrossProfit    float64
	TotalOpExpense float64
	NetProfit      float64
}

// ─── Cash Flow ─────────────────────────────────────────────────────────────────

// CashFlowLine is one line in a cash flow section.
type CashFlowLine struct {
	Description string
	Amount      float64 // positive = inflow, negative = outflow
}

// CashFlow is the statement of cash flows.
type CashFlow struct {
	Period           ReportPeriod
	Operating        []*CashFlowLine
	Investing        []*CashFlowLine
	Financing        []*CashFlowLine
	NetOperating     float64
	NetInvesting     float64
	NetFinancing     float64
	OpeningBalance   float64
	NetChange        float64
	ClosingBalance   float64
}

// ─── General Ledger ────────────────────────────────────────────────────────────

// LedgerEntry is one row in the general ledger.
type LedgerEntry struct {
	Date           time.Time
	ReferenceNo    string
	Description    string
	Debit          float64
	Credit         float64
	RunningBalance float64
}

// GeneralLedger is the per-account ledger.
type GeneralLedger struct {
	AccountCode    string
	AccountName    string
	Period         ReportPeriod
	OpeningBalance float64
	Entries        []*LedgerEntry
	TotalDebit     float64
	TotalCredit    float64
	ClosingBalance float64
}

// ─── Trial Balance ─────────────────────────────────────────────────────────────

// TrialBalanceLine is one account row.
type TrialBalanceLine struct {
	AccountCode string
	AccountName string
	AccountType string
	Debit       float64
	Credit      float64
}

// TrialBalance is the trial balance report.
type TrialBalance struct {
	Period      ReportPeriod
	Lines       []*TrialBalanceLine
	TotalDebit  float64
	TotalCredit float64
	IsBalanced  bool
}

// ─── Repository Interface ───────────────────────────────────────────────────────

// ReportReadRepository is the read-side for all financial report queries.
type ReportReadRepository interface {
	GetBalanceSheet(ctx context.Context, p ReportPeriod) (*BalanceSheet, error)
	GetProfitLoss(ctx context.Context, p ReportPeriod) (*ProfitLoss, error)
	GetCashFlow(ctx context.Context, p ReportPeriod) (*CashFlow, error)
	GetGeneralLedger(ctx context.Context, accountCode string, p ReportPeriod) (*GeneralLedger, error)
	GetTrialBalance(ctx context.Context, p ReportPeriod) (*TrialBalance, error)
}
