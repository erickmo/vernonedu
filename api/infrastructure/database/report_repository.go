package database

import (
	"context"
	"fmt"
	"math"
	"sort"
	"time"

	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

// ReportRepository implements accounting.ReportReadRepository.
// All queries aggregate from accounting_transactions + chart_of_accounts.
// Branch filtering is a future extension; the schema does not yet carry branch_id on transactions.
type ReportRepository struct {
	db *sqlx.DB
}

func NewReportRepository(db *sqlx.DB) *ReportRepository {
	return &ReportRepository{db: db}
}

// ─── helpers ──────────────────────────────────────────────────────────────────

type accountBalance struct {
	Code        string  `db:"code"`
	Name        string  `db:"name"`
	AccountType string  `db:"account_type"`
	ParentCode  string  `db:"parent_code"`
	TotalDebit  float64 `db:"total_debit"`
	TotalCredit float64 `db:"total_credit"`
}

// accountBalances fetches debit and credit totals per account for completed transactions.
// dateFilter restricts to transaction_date <= to (for balance sheet).
// periodFilter restricts to a date range (for P&L, trial balance, general ledger).
func (r *ReportRepository) accountBalances(
	ctx context.Context,
	from, to time.Time,
	accountTypeFilter string, // "" = all types
	periodOnly bool, // true = use from/to range; false = from beginning until to
) ([]accountBalance, error) {
	fromClause := `'0001-01-01'::date`
	if periodOnly {
		fromClause = `$3::date`
	}

	typeClause := `AND c.account_type = $4`
	if accountTypeFilter == "" {
		typeClause = `AND ($4 = '' OR c.account_type = $4)`
	}

	query := fmt.Sprintf(`
		SELECT
			c.code,
			c.name,
			c.account_type,
			COALESCE(c.parent_code, '') AS parent_code,
			COALESCE(SUM(CASE WHEN t.debit_account_code = c.code  THEN t.amount ELSE 0 END), 0) AS total_debit,
			COALESCE(SUM(CASE WHEN t.credit_account_code = c.code THEN t.amount ELSE 0 END), 0) AS total_credit
		FROM chart_of_accounts c
		LEFT JOIN accounting_transactions t
			ON (t.debit_account_code = c.code OR t.credit_account_code = c.code)
			AND t.status = 'completed'
			AND t.transaction_date >= %s
			AND t.transaction_date <= $2::date
		WHERE c.is_active = true
		%s
		GROUP BY c.code, c.name, c.account_type, c.parent_code
		ORDER BY c.code
	`, fromClause, typeClause)

	var rows []accountBalance
	var err error
	if periodOnly {
		err = r.db.SelectContext(ctx, &rows, query, to, to, from, accountTypeFilter)
	} else {
		err = r.db.SelectContext(ctx, &rows, query, to, to, accountTypeFilter)
	}
	if err != nil {
		return nil, fmt.Errorf("accountBalances query failed: %w", err)
	}
	return rows, nil
}

// netBalance returns the natural-sign balance of an account.
// Asset / Expense: debit-normal → balance = debit - credit
// Liability / Equity / Revenue: credit-normal → balance = credit - debit
func netBalance(at string, debit, credit float64) float64 {
	switch at {
	case "asset", "expense":
		return debit - credit
	default:
		return credit - debit
	}
}

// round2 rounds to 2 decimal places.
func round2(v float64) float64 { return math.Round(v*100) / 100 }

// ─── Balance Sheet ─────────────────────────────────────────────────────────────

func (r *ReportRepository) GetBalanceSheet(ctx context.Context, p accounting.ReportPeriod) (*accounting.BalanceSheet, error) {
	rows, err := r.accountBalances(ctx, p.From, p.To, "", false)
	if err != nil {
		return nil, err
	}

	bs := &accounting.BalanceSheet{Period: p}
	for _, row := range rows {
		bal := round2(netBalance(row.AccountType, row.TotalDebit, row.TotalCredit))
		line := &accounting.BalanceSheetLine{
			AccountCode: row.Code,
			AccountName: row.Name,
			AccountType: row.AccountType,
			ParentCode:  row.ParentCode,
			Balance:     bal,
		}
		switch row.AccountType {
		case "asset":
			bs.Assets = append(bs.Assets, line)
			bs.TotalAssets = round2(bs.TotalAssets + bal)
		case "liability":
			bs.Liabilities = append(bs.Liabilities, line)
			bs.TotalLiab = round2(bs.TotalLiab + bal)
		case "equity":
			bs.Equity = append(bs.Equity, line)
			bs.TotalEquity = round2(bs.TotalEquity + bal)
		}
	}
	bs.IsBalanced = math.Abs(bs.TotalAssets-(bs.TotalLiab+bs.TotalEquity)) < 0.01
	return bs, nil
}

// ─── Profit & Loss ─────────────────────────────────────────────────────────────

func (r *ReportRepository) GetProfitLoss(ctx context.Context, p accounting.ReportPeriod) (*accounting.ProfitLoss, error) {
	rows, err := r.accountBalances(ctx, p.From, p.To, "", true)
	if err != nil {
		return nil, err
	}

	pl := &accounting.ProfitLoss{Period: p}
	for _, row := range rows {
		bal := round2(netBalance(row.AccountType, row.TotalDebit, row.TotalCredit))
		switch row.AccountType {
		case "revenue":
			pl.Revenue = append(pl.Revenue, &accounting.PLLine{
				AccountCode: row.Code,
				AccountName: row.Name,
				ParentCode:  row.ParentCode,
				Amount:      bal,
			})
			pl.TotalRevenue = round2(pl.TotalRevenue + bal)
		case "expense":
			line := &accounting.PLLine{
				AccountCode: row.Code,
				AccountName: row.Name,
				ParentCode:  row.ParentCode,
				Amount:      bal,
			}
			// 5100 codes = HPP (Harga Pokok Pendapatan / COGS)
			if len(row.Code) >= 4 && row.Code[:2] == "51" {
				pl.HPP = append(pl.HPP, line)
				pl.TotalHPP = round2(pl.TotalHPP + bal)
			} else {
				pl.OpExpenses = append(pl.OpExpenses, line)
				pl.TotalOpExpense = round2(pl.TotalOpExpense + bal)
			}
		}
	}
	pl.GrossProfit = round2(pl.TotalRevenue - pl.TotalHPP)
	pl.NetProfit = round2(pl.GrossProfit - pl.TotalOpExpense)
	return pl, nil
}

// ─── Cash Flow ─────────────────────────────────────────────────────────────────

type cashFlowRow struct {
	Description string  `db:"description"`
	Category    string  `db:"category"`
	TxType      string  `db:"transaction_type"`
	TotalAmount float64 `db:"total_amount"`
}

func (r *ReportRepository) GetCashFlow(ctx context.Context, p accounting.ReportPeriod) (*accounting.CashFlow, error) {
	query := `
		SELECT
			COALESCE(category, description) AS description,
			COALESCE(category, '') AS category,
			transaction_type,
			SUM(amount) AS total_amount
		FROM accounting_transactions
		WHERE status = 'completed'
		  AND transaction_date >= $1::date
		  AND transaction_date <= $2::date
		GROUP BY category, description, transaction_type
		ORDER BY transaction_type, category
	`
	var rows []cashFlowRow
	if err := r.db.SelectContext(ctx, &rows, query, p.From, p.To); err != nil {
		return nil, fmt.Errorf("cash flow query failed: %w", err)
	}

	// Opening balance = cumulative net cash before period start
	type singleVal struct{ V float64 }
	var opening singleVal
	openingQuery := `
		SELECT COALESCE(SUM(CASE WHEN transaction_type='income' THEN amount ELSE -amount END), 0) AS v
		FROM accounting_transactions
		WHERE status = 'completed'
		  AND transaction_date < $1::date
		  AND transaction_type IN ('income','expense')
	`
	if err := r.db.GetContext(ctx, &opening, openingQuery, p.From); err != nil {
		return nil, fmt.Errorf("opening balance query failed: %w", err)
	}

	cf := &accounting.CashFlow{
		Period:         p,
		OpeningBalance: round2(opening.V),
	}

	for _, row := range rows {
		amt := round2(row.TotalAmount)
		if row.TxType == "expense" {
			amt = -amt
		}
		line := &accounting.CashFlowLine{Description: row.Description, Amount: amt}

		// Classify by category keywords and account type:
		// - investing: contains "peralatan", "investasi", "aset tetap"
		// - financing: contains "modal", "pinjaman", "pendanaan"
		// - default: operating
		cat := row.Category
		switch {
		case contains(cat, "peralatan", "investasi", "aset tetap", "fixed asset"):
			cf.Investing = append(cf.Investing, line)
			cf.NetInvesting = round2(cf.NetInvesting + amt)
		case contains(cat, "modal", "pinjaman", "pendanaan", "financing"):
			cf.Financing = append(cf.Financing, line)
			cf.NetFinancing = round2(cf.NetFinancing + amt)
		default:
			cf.Operating = append(cf.Operating, line)
			cf.NetOperating = round2(cf.NetOperating + amt)
		}
	}

	cf.NetChange = round2(cf.NetOperating + cf.NetInvesting + cf.NetFinancing)
	cf.ClosingBalance = round2(cf.OpeningBalance + cf.NetChange)
	return cf, nil
}

// contains checks if s contains any of the substrings (case-insensitive prefix match).
func contains(s string, subs ...string) bool {
	for _, sub := range subs {
		for i := 0; i+len(sub) <= len(s); i++ {
			if equalFold(s[i:i+len(sub)], sub) {
				return true
			}
		}
	}
	return false
}

func equalFold(a, b string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		ca, cb := a[i], b[i]
		if ca >= 'A' && ca <= 'Z' {
			ca += 32
		}
		if cb >= 'A' && cb <= 'Z' {
			cb += 32
		}
		if ca != cb {
			return false
		}
	}
	return true
}

// ─── General Ledger ────────────────────────────────────────────────────────────

type ledgerRow struct {
	TxDate      time.Time `db:"transaction_date"`
	RefNo       string    `db:"reference_number"`
	Description string    `db:"description"`
	IsDebit     bool      `db:"is_debit"`
	Amount      float64   `db:"amount"`
}

func (r *ReportRepository) GetGeneralLedger(ctx context.Context, accountCode string, p accounting.ReportPeriod) (*accounting.GeneralLedger, error) {
	// Opening balance: net debit activity before From
	type singleVal struct{ V float64 }
	var ob singleVal
	obQuery := `
		SELECT COALESCE(
			SUM(CASE
				WHEN debit_account_code = $1 THEN amount
				WHEN credit_account_code = $1 THEN -amount
				ELSE 0
			END), 0) AS v
		FROM accounting_transactions
		WHERE status = 'completed'
		  AND transaction_date < $2::date
		  AND (debit_account_code = $1 OR credit_account_code = $1)
	`
	if err := r.db.GetContext(ctx, &ob, obQuery, accountCode, p.From); err != nil {
		return nil, fmt.Errorf("opening balance query failed: %w", err)
	}

	// Account metadata
	type acctMeta struct {
		Code string `db:"code"`
		Name string `db:"name"`
		Type string `db:"account_type"`
	}
	var meta acctMeta
	if err := r.db.GetContext(ctx, &meta, `SELECT code, name, account_type FROM chart_of_accounts WHERE code = $1`, accountCode); err != nil {
		return nil, fmt.Errorf("account not found %q: %w", accountCode, err)
	}

	// Period entries
	query := `
		SELECT
			transaction_date,
			COALESCE(reference_number, '') AS reference_number,
			description,
			(debit_account_code = $1) AS is_debit,
			amount
		FROM accounting_transactions
		WHERE status = 'completed'
		  AND transaction_date >= $2::date
		  AND transaction_date <= $3::date
		  AND (debit_account_code = $1 OR credit_account_code = $1)
		ORDER BY transaction_date, created_at
	`
	var rows []ledgerRow
	if err := r.db.SelectContext(ctx, &rows, query, accountCode, p.From, p.To); err != nil {
		return nil, fmt.Errorf("ledger entries query failed: %w", err)
	}

	gl := &accounting.GeneralLedger{
		AccountCode:    meta.Code,
		AccountName:    meta.Name,
		Period:         p,
		OpeningBalance: round2(ob.V),
	}

	running := ob.V
	for _, row := range rows {
		var debit, credit float64
		if row.IsDebit {
			debit = row.Amount
			running += row.Amount
		} else {
			credit = row.Amount
			running -= row.Amount
		}
		gl.TotalDebit = round2(gl.TotalDebit + debit)
		gl.TotalCredit = round2(gl.TotalCredit + credit)
		gl.Entries = append(gl.Entries, &accounting.LedgerEntry{
			Date:           row.TxDate,
			ReferenceNo:    row.RefNo,
			Description:    row.Description,
			Debit:          round2(debit),
			Credit:         round2(credit),
			RunningBalance: round2(running),
		})
	}
	gl.ClosingBalance = round2(running)
	return gl, nil
}

// ─── Trial Balance ─────────────────────────────────────────────────────────────

func (r *ReportRepository) GetTrialBalance(ctx context.Context, p accounting.ReportPeriod) (*accounting.TrialBalance, error) {
	rows, err := r.accountBalances(ctx, p.From, p.To, "", true)
	if err != nil {
		return nil, err
	}

	tb := &accounting.TrialBalance{Period: p}
	for _, row := range rows {
		// Only include accounts with activity
		if row.TotalDebit == 0 && row.TotalCredit == 0 {
			continue
		}
		tb.Lines = append(tb.Lines, &accounting.TrialBalanceLine{
			AccountCode: row.Code,
			AccountName: row.Name,
			AccountType: row.AccountType,
			Debit:       round2(row.TotalDebit),
			Credit:      round2(row.TotalCredit),
		})
		tb.TotalDebit = round2(tb.TotalDebit + row.TotalDebit)
		tb.TotalCredit = round2(tb.TotalCredit + row.TotalCredit)
	}

	// Sort by account code
	sort.Slice(tb.Lines, func(i, j int) bool {
		return tb.Lines[i].AccountCode < tb.Lines[j].AccountCode
	})

	tb.IsBalanced = math.Abs(tb.TotalDebit-tb.TotalCredit) < 0.01
	return tb, nil
}
