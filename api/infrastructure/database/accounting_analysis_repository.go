package database

import (
	"context"
	"fmt"
	"time"

	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type AccountingAnalysisRepository struct {
	db *sqlx.DB
}

func NewAccountingAnalysisRepository(db *sqlx.DB) *AccountingAnalysisRepository {
	return &AccountingAnalysisRepository{db: db}
}

// buildRatioMetric constructs a RatioMetric with trend and change calculations.
func buildRatioMetric(current, previous float64) accounting.RatioMetric {
	var changePct float64
	if previous != 0 {
		changePct = (current - previous) / previous * 100
	}
	change := current - previous
	trend := "flat"
	if changePct > 0.5 {
		trend = "up"
	} else if changePct < -0.5 {
		trend = "down"
	}
	return accounting.RatioMetric{
		Current:   current,
		Previous:  previous,
		Change:    change,
		ChangePct: changePct,
		Trend:     trend,
	}
}

// periodDateRange returns SQL-compatible date range strings for the given params.
func periodDateRange(params accounting.PeriodParams) (startDate, endDate string) {
	now := time.Now()
	month := params.Month
	year := params.Year
	if month == 0 {
		month = int(now.Month())
	}
	if year == 0 {
		year = now.Year()
	}

	switch params.Period {
	case "custom":
		return params.StartDate, params.EndDate
	case "quarterly":
		q := (month-1)/3 + 1
		qStart := (q-1)*3 + 1
		start := fmt.Sprintf("%04d-%02d-01", year, qStart)
		end := fmt.Sprintf("%04d-%02d-01", year, qStart+3)
		return start, end
	case "yearly":
		return fmt.Sprintf("%04d-01-01", year), fmt.Sprintf("%04d-01-01", year+1)
	default: // monthly
		nextMonth := month + 1
		nextYear := year
		if nextMonth > 12 {
			nextMonth = 1
			nextYear++
		}
		start := fmt.Sprintf("%04d-%02d-01", year, month)
		end := fmt.Sprintf("%04d-%02d-01", nextYear, nextMonth)
		return start, end
	}
}

// prevPeriodDateRange returns the previous period date range based on Comparison field.
func prevPeriodDateRange(params accounting.PeriodParams) (startDate, endDate string) {
	now := time.Now()
	month := params.Month
	year := params.Year
	if month == 0 {
		month = int(now.Month())
	}
	if year == 0 {
		year = now.Year()
	}

	comparison := params.Comparison
	if comparison == "" {
		comparison = "prev_month"
	}

	switch comparison {
	case "prev_year":
		prevYear := year - 1
		return fmt.Sprintf("%04d-01-01", prevYear), fmt.Sprintf("%04d-01-01", year)
	case "prev_quarter":
		q := (month-1)/3 + 1
		prevQ := q - 1
		prevYear := year
		if prevQ < 1 {
			prevQ = 4
			prevYear--
		}
		qStart := (prevQ-1)*3 + 1
		start := fmt.Sprintf("%04d-%02d-01", prevYear, qStart)
		end := fmt.Sprintf("%04d-%02d-01", prevYear, qStart+3)
		return start, end
	default: // prev_month
		prevMonth := month - 1
		prevYear := year
		if prevMonth < 1 {
			prevMonth = 12
			prevYear--
		}
		nextMonth := month
		nextYear := year
		start := fmt.Sprintf("%04d-%02d-01", prevYear, prevMonth)
		end := fmt.Sprintf("%04d-%02d-01", nextYear, nextMonth)
		return start, end
	}
}

// GetFinancialRatios computes financial ratio metrics for the given period vs previous period.
func (r *AccountingAnalysisRepository) GetFinancialRatios(ctx context.Context, params accounting.PeriodParams) (*accounting.FinancialRatiosResult, error) {
	startDate, endDate := periodDateRange(params)
	prevStart, prevEnd := prevPeriodDateRange(params)

	type totals struct {
		Income  float64 `db:"income"`
		Expense float64 `db:"expense"`
	}

	fetchTotals := func(start, end string) (totals, error) {
		var t totals
		err := r.db.QueryRowxContext(ctx, `
			SELECT
				COALESCE(SUM(CASE WHEN transaction_type='income' THEN amount ELSE 0 END), 0) AS income,
				COALESCE(SUM(CASE WHEN transaction_type='expense' THEN amount ELSE 0 END), 0) AS expense
			FROM accounting_transactions
			WHERE status = 'completed'
			  AND transaction_date >= $1
			  AND transaction_date < $2
		`, start, end).StructScan(&t)
		return t, err
	}

	cur, err := fetchTotals(startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("fetchTotals current: %w", err)
	}
	prev, err := fetchTotals(prevStart, prevEnd)
	if err != nil {
		return nil, fmt.Errorf("fetchTotals previous: %w", err)
	}

	// Collection rate from invoices
	type invoiceTotals struct {
		PaidAmount  float64 `db:"paid_amount"`
		TotalAmount float64 `db:"total_amount"`
		PaidCount   int     `db:"paid_count"`
	}

	fetchInvoiceTotals := func(start, end string) (invoiceTotals, error) {
		var it invoiceTotals
		err := r.db.QueryRowxContext(ctx, `
			SELECT
				COALESCE(SUM(CASE WHEN status='paid' THEN amount ELSE 0 END), 0) AS paid_amount,
				COALESCE(SUM(amount), 0) AS total_amount,
				COUNT(CASE WHEN status='paid' THEN 1 END) AS paid_count
			FROM accounting_invoices
			WHERE created_at >= $1
			  AND created_at < $2
		`, start, end).StructScan(&it)
		return it, err
	}

	curInv, err := fetchInvoiceTotals(startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("fetchInvoiceTotals current: %w", err)
	}
	prevInv, err := fetchInvoiceTotals(prevStart, prevEnd)
	if err != nil {
		return nil, fmt.Errorf("fetchInvoiceTotals previous: %w", err)
	}

	// Compute current ratios
	var curProfitMargin, prevProfitMargin float64
	if cur.Income > 0 {
		curProfitMargin = (cur.Income - cur.Expense) / cur.Income * 100
	}
	if prev.Income > 0 {
		prevProfitMargin = (prev.Income - prev.Expense) / prev.Income * 100
	}

	var curExpenseRatio, prevExpenseRatio float64
	if cur.Income > 0 {
		curExpenseRatio = cur.Expense / cur.Income * 100
	}
	if prev.Income > 0 {
		prevExpenseRatio = prev.Expense / prev.Income * 100
	}

	// Student counts (use paid invoice count as proxy)
	curStudentCount := float64(curInv.PaidCount)
	prevStudentCount := float64(prevInv.PaidCount)

	var curRevPerStudent, prevRevPerStudent float64
	if curStudentCount > 0 {
		curRevPerStudent = cur.Income / curStudentCount
	}
	if prevStudentCount > 0 {
		prevRevPerStudent = prev.Income / prevStudentCount
	}

	var curCostPerStudent, prevCostPerStudent float64
	if curStudentCount > 0 {
		curCostPerStudent = cur.Expense / curStudentCount
	}
	if prevStudentCount > 0 {
		prevCostPerStudent = prev.Expense / prevStudentCount
	}

	// Avg batch profitability
	type batchAvg struct {
		AvgMargin float64 `db:"avg_margin"`
		Count     int     `db:"cnt"`
	}

	fetchBatchAvg := func(start, end string) (batchAvg, error) {
		var ba batchAvg
		err := r.db.QueryRowxContext(ctx, `
			WITH batch_totals AS (
				SELECT
					related_entity_id,
					SUM(CASE WHEN transaction_type='income' THEN amount ELSE 0 END) AS revenue,
					SUM(CASE WHEN transaction_type='expense' THEN amount ELSE 0 END) AS expense
				FROM accounting_transactions
				WHERE related_entity_type = 'batch'
				  AND related_entity_id IS NOT NULL
				  AND status = 'completed'
				  AND transaction_date >= $1
				  AND transaction_date < $2
				GROUP BY related_entity_id
			)
			SELECT
				COALESCE(AVG(CASE WHEN revenue > 0 THEN (revenue - expense) / revenue * 100 ELSE 0 END), 0) AS avg_margin,
				COUNT(*) AS cnt
			FROM batch_totals
		`, start, end).StructScan(&ba)
		return ba, err
	}

	curBatch, err := fetchBatchAvg(startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("fetchBatchAvg current: %w", err)
	}
	prevBatch, err := fetchBatchAvg(prevStart, prevEnd)
	if err != nil {
		return nil, fmt.Errorf("fetchBatchAvg previous: %w", err)
	}

	// Collection rate
	var curCollectionRate, prevCollectionRate float64
	if curInv.TotalAmount > 0 {
		curCollectionRate = curInv.PaidAmount / curInv.TotalAmount * 100
	}
	if prevInv.TotalAmount > 0 {
		prevCollectionRate = prevInv.PaidAmount / prevInv.TotalAmount * 100
	}

	// Days sales outstanding: (receivables / daily_revenue)
	// receivables = total_amount - paid_amount
	curReceivables := curInv.TotalAmount - curInv.PaidAmount
	prevReceivables := prevInv.TotalAmount - prevInv.PaidAmount

	// Days in period (approx 30)
	daysInPeriod := 30.0
	var curDSO, prevDSO float64
	if cur.Income > 0 {
		dailyRev := cur.Income / daysInPeriod
		curDSO = curReceivables / dailyRev
	}
	if prev.Income > 0 {
		dailyRev := prev.Income / daysInPeriod
		prevDSO = prevReceivables / dailyRev
	}

	// Revenue growth rate
	var curGrowth, prevGrowth float64
	if prev.Income > 0 {
		curGrowth = (cur.Income - prev.Income) / prev.Income * 100
	}
	// For previous comparison, we'd need two-periods-back data; use 0 as fallback
	prevGrowth = 0

	result := &accounting.FinancialRatiosResult{
		ProfitMargin:          buildRatioMetric(curProfitMargin, prevProfitMargin),
		ExpenseRatio:          buildRatioMetric(curExpenseRatio, prevExpenseRatio),
		RevenuePerStudent:     buildRatioMetric(curRevPerStudent, prevRevPerStudent),
		CostPerStudent:        buildRatioMetric(curCostPerStudent, prevCostPerStudent),
		AvgBatchProfitability: buildRatioMetric(curBatch.AvgMargin, prevBatch.AvgMargin),
		CollectionRate:        buildRatioMetric(curCollectionRate, prevCollectionRate),
		DaysSalesOutstanding:  buildRatioMetric(curDSO, prevDSO),
		RevenueGrowthRate:     buildRatioMetric(curGrowth, prevGrowth),
	}

	return result, nil
}

// GetRevenueAnalysis returns monthly trend and grouped revenue data.
func (r *AccountingAnalysisRepository) GetRevenueAnalysis(ctx context.Context, params accounting.PeriodParams, groupBy string) (*accounting.RevenueAnalysisResult, error) {
	// Monthly trend — last 12 months
	type monthlyRow struct {
		Month   string  `db:"month"`
		Total   float64 `db:"total"`
		Regular float64 `db:"regular"`
		Career  float64 `db:"career"`
		Inhouse float64 `db:"inhouse"`
		Collab  float64 `db:"collab"`
		Cert    float64 `db:"cert"`
	}

	rows, err := r.db.QueryxContext(ctx, `
		SELECT
			TO_CHAR(transaction_date, 'YYYY-MM') AS month,
			COALESCE(SUM(amount), 0) AS total,
			COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%reguler%' OR LOWER(category) LIKE '%regular%' THEN amount ELSE 0 END), 0) AS regular,
			COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%program karir%' OR LOWER(category) LIKE '%career%' OR LOWER(category) LIKE '%karir%' THEN amount ELSE 0 END), 0) AS career,
			COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%inhouse%' OR LOWER(category) LIKE '%in-house%' THEN amount ELSE 0 END), 0) AS inhouse,
			COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%kolaborasi%' OR LOWER(category) LIKE '%collab%' THEN amount ELSE 0 END), 0) AS collab,
			COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%sertifikat%' OR LOWER(category) LIKE '%cert%' THEN amount ELSE 0 END), 0) AS cert
		FROM accounting_transactions
		WHERE transaction_type = 'income'
		  AND status = 'completed'
		  AND transaction_date >= NOW() - INTERVAL '12 months'
		GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
		ORDER BY month
	`)
	if err != nil {
		return nil, fmt.Errorf("GetRevenueAnalysis monthly trend: %w", err)
	}
	defer rows.Close()

	var monthlyTrend []accounting.MonthlyRevenueTrend
	var totalRevenue float64
	for rows.Next() {
		var row monthlyRow
		if err := rows.StructScan(&row); err != nil {
			return nil, fmt.Errorf("scan monthly revenue row: %w", err)
		}
		monthlyTrend = append(monthlyTrend, accounting.MonthlyRevenueTrend{
			Month:   row.Month,
			Total:   row.Total,
			Regular: row.Regular,
			Career:  row.Career,
			Inhouse: row.Inhouse,
			Collab:  row.Collab,
			Cert:    row.Cert,
		})
		totalRevenue += row.Total
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows error: %w", err)
	}

	// By group
	type groupRow struct {
		GroupKey   string  `db:"group_key"`
		Revenue    float64 `db:"revenue"`
		BatchCount int     `db:"batch_count"`
	}

	var groupRows []groupRow
	switch groupBy {
	case "course_type", "":
		gRows, err := r.db.QueryxContext(ctx, `
			SELECT
				COALESCE(NULLIF(TRIM(category), ''), 'other') AS group_key,
				COALESCE(SUM(amount), 0) AS revenue,
				COUNT(DISTINCT related_entity_id) AS batch_count
			FROM accounting_transactions
			WHERE transaction_type = 'income'
			  AND status = 'completed'
			  AND transaction_date >= NOW() - INTERVAL '12 months'
			GROUP BY COALESCE(NULLIF(TRIM(category), ''), 'other')
			ORDER BY revenue DESC
		`)
		if err != nil {
			return nil, fmt.Errorf("GetRevenueAnalysis by group: %w", err)
		}
		defer gRows.Close()
		for gRows.Next() {
			var gr groupRow
			if err := gRows.StructScan(&gr); err != nil {
				return nil, fmt.Errorf("scan group row: %w", err)
			}
			groupRows = append(groupRows, gr)
		}
		if err := gRows.Err(); err != nil {
			return nil, fmt.Errorf("group rows error: %w", err)
		}
	}

	var byGroup []accounting.RevenueByGroup
	for _, gr := range groupRows {
		pct := 0.0
		avg := 0.0
		if totalRevenue > 0 {
			pct = gr.Revenue / totalRevenue * 100
		}
		if gr.BatchCount > 0 {
			avg = gr.Revenue / float64(gr.BatchCount)
		}
		byGroup = append(byGroup, accounting.RevenueByGroup{
			GroupKey:    gr.GroupKey,
			Revenue:     gr.Revenue,
			PctOfTotal:  pct,
			BatchCount:  gr.BatchCount,
			AvgPerBatch: avg,
			Trend:       "flat",
		})
	}

	if groupBy == "" {
		groupBy = "course_type"
	}

	return &accounting.RevenueAnalysisResult{
		MonthlyTrend: monthlyTrend,
		ByGroup:      byGroup,
		TotalRevenue: totalRevenue,
		GroupBy:      groupBy,
	}, nil
}

// GetCostAnalysis returns monthly cost trend and breakdown by category.
func (r *AccountingAnalysisRepository) GetCostAnalysis(ctx context.Context, params accounting.PeriodParams, groupBy string) (*accounting.CostAnalysisResult, error) {
	type monthlyRow struct {
		Month       string  `db:"month"`
		Total       float64 `db:"total"`
		Facilitator float64 `db:"facilitator"`
		Commission  float64 `db:"commission"`
		Operational float64 `db:"operational"`
		Marketing   float64 `db:"marketing"`
		Other       float64 `db:"other"`
	}

	rows, err := r.db.QueryxContext(ctx, `
		SELECT
			TO_CHAR(transaction_date, 'YYYY-MM') AS month,
			COALESCE(SUM(amount), 0) AS total,
			COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%fasilitator%' OR LOWER(category) LIKE '%facilitator%' THEN amount ELSE 0 END), 0) AS facilitator,
			COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%komisi%' OR LOWER(category) LIKE '%commission%' THEN amount ELSE 0 END), 0) AS commission,
			COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%operasional%' OR LOWER(category) LIKE '%operational%' THEN amount ELSE 0 END), 0) AS operational,
			COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%marketing%' OR LOWER(category) LIKE '%pemasaran%' THEN amount ELSE 0 END), 0) AS marketing,
			COALESCE(SUM(CASE WHEN
				LOWER(category) NOT LIKE '%fasilitator%' AND LOWER(category) NOT LIKE '%facilitator%'
				AND LOWER(category) NOT LIKE '%komisi%' AND LOWER(category) NOT LIKE '%commission%'
				AND LOWER(category) NOT LIKE '%operasional%' AND LOWER(category) NOT LIKE '%operational%'
				AND LOWER(category) NOT LIKE '%marketing%' AND LOWER(category) NOT LIKE '%pemasaran%'
			THEN amount ELSE 0 END), 0) AS other
		FROM accounting_transactions
		WHERE transaction_type = 'expense'
		  AND status = 'completed'
		  AND transaction_date >= NOW() - INTERVAL '12 months'
		GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
		ORDER BY month
	`)
	if err != nil {
		return nil, fmt.Errorf("GetCostAnalysis monthly trend: %w", err)
	}
	defer rows.Close()

	var monthlyTrend []accounting.MonthlyCostTrend
	var totalCost float64
	for rows.Next() {
		var row monthlyRow
		if err := rows.StructScan(&row); err != nil {
			return nil, fmt.Errorf("scan monthly cost row: %w", err)
		}
		monthlyTrend = append(monthlyTrend, accounting.MonthlyCostTrend{
			Month:       row.Month,
			Total:       row.Total,
			Facilitator: row.Facilitator,
			Commission:  row.Commission,
			Operational: row.Operational,
			Marketing:   row.Marketing,
			Other:       row.Other,
		})
		totalCost += row.Total
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("monthly cost rows error: %w", err)
	}

	// By category
	type catRow struct {
		Category string  `db:"category"`
		Amount   float64 `db:"amount"`
	}

	catRows, err := r.db.QueryxContext(ctx, `
		SELECT
			COALESCE(NULLIF(TRIM(category), ''), 'other') AS category,
			COALESCE(SUM(amount), 0) AS amount
		FROM accounting_transactions
		WHERE transaction_type = 'expense'
		  AND status = 'completed'
		  AND transaction_date >= NOW() - INTERVAL '12 months'
		GROUP BY COALESCE(NULLIF(TRIM(category), ''), 'other')
		ORDER BY amount DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("GetCostAnalysis by category: %w", err)
	}
	defer catRows.Close()

	// Also get previous month totals per category for vs_previous
	type catPrevRow struct {
		Category string  `db:"category"`
		Amount   float64 `db:"amount"`
	}
	prevCatMap := map[string]float64{}

	now := time.Now()
	prevMonth := int(now.Month()) - 1
	prevYear := now.Year()
	if prevMonth < 1 {
		prevMonth = 12
		prevYear--
	}
	prevMonthStr := fmt.Sprintf("%04d-%02d-01", prevYear, prevMonth)
	curMonthStr := fmt.Sprintf("%04d-%02d-01", now.Year(), int(now.Month()))

	prevCatRows, err := r.db.QueryxContext(ctx, `
		SELECT
			COALESCE(NULLIF(TRIM(category), ''), 'other') AS category,
			COALESCE(SUM(amount), 0) AS amount
		FROM accounting_transactions
		WHERE transaction_type = 'expense'
		  AND status = 'completed'
		  AND transaction_date >= $1
		  AND transaction_date < $2
		GROUP BY COALESCE(NULLIF(TRIM(category), ''), 'other')
	`, prevMonthStr, curMonthStr)
	if err == nil {
		defer prevCatRows.Close()
		for prevCatRows.Next() {
			var pc catPrevRow
			if err := prevCatRows.StructScan(&pc); err == nil {
				prevCatMap[pc.Category] = pc.Amount
			}
		}
	}

	var byCategory []accounting.CostByGroup
	for catRows.Next() {
		var cr catRow
		if err := catRows.StructScan(&cr); err != nil {
			return nil, fmt.Errorf("scan category row: %w", err)
		}
		pct := 0.0
		if totalCost > 0 {
			pct = cr.Amount / totalCost * 100
		}
		prevAmt := prevCatMap[cr.Category]
		diff := cr.Amount - prevAmt
		trend := "flat"
		if prevAmt > 0 {
			pct12 := diff / prevAmt * 100
			if pct12 > 0.5 {
				trend = "up"
			} else if pct12 < -0.5 {
				trend = "down"
			}
		}
		byCategory = append(byCategory, accounting.CostByGroup{
			Category:   cr.Category,
			Amount:     cr.Amount,
			PctOfTotal: pct,
			VsPrevious: diff,
			Trend:      trend,
		})
	}
	if err := catRows.Err(); err != nil {
		return nil, fmt.Errorf("category rows error: %w", err)
	}

	return &accounting.CostAnalysisResult{
		MonthlyTrend: monthlyTrend,
		ByCategory:   byCategory,
		TotalCost:    totalCost,
	}, nil
}

// GetBatchProfitability returns per-batch profit data sorted by margin.
func (r *AccountingAnalysisRepository) GetBatchProfitability(ctx context.Context, params accounting.PeriodParams, sort string, limit int) (*accounting.BatchProfitResult, error) {
	if limit <= 0 {
		limit = 10
	}

	orderDir := "DESC"
	if sort == "bottom" {
		orderDir = "ASC"
	}

	query := fmt.Sprintf(`
		WITH batch_txns AS (
			SELECT
				related_entity_id::text AS batch_id,
				COALESCE(SUM(CASE WHEN transaction_type='income' THEN amount ELSE 0 END), 0) AS revenue,
				COALESCE(SUM(CASE WHEN transaction_type='expense'
					AND LOWER(category) NOT LIKE '%%komisi%%'
					AND LOWER(category) NOT LIKE '%%commission%%'
				THEN amount ELSE 0 END), 0) AS expense,
				COALESCE(SUM(CASE WHEN LOWER(category) LIKE '%%komisi%%' OR LOWER(category) LIKE '%%commission%%' THEN amount ELSE 0 END), 0) AS commission
			FROM accounting_transactions
			WHERE related_entity_type = 'batch'
			  AND related_entity_id IS NOT NULL
			  AND status = 'completed'
			GROUP BY related_entity_id
		)
		SELECT
			bt.batch_id,
			COALESCE(cb.code, bt.batch_id) AS batch_code,
			COALESCE(mc.name, '') AS course_name,
			bt.revenue,
			bt.expense,
			bt.commission
		FROM batch_txns bt
		LEFT JOIN course_batches cb ON cb.id = bt.batch_id::uuid
		LEFT JOIN master_courses mc ON mc.id = cb.master_course_id
		WHERE bt.revenue > 0
		ORDER BY (bt.revenue - bt.expense - bt.commission) / NULLIF(bt.revenue, 0) %s
		LIMIT $1
	`, orderDir)

	type batchRow struct {
		BatchID    string  `db:"batch_id"`
		BatchCode  string  `db:"batch_code"`
		CourseName string  `db:"course_name"`
		Revenue    float64 `db:"revenue"`
		Expense    float64 `db:"expense"`
		Commission float64 `db:"commission"`
	}

	rows, err := r.db.QueryxContext(ctx, query, limit)
	if err != nil {
		return nil, fmt.Errorf("GetBatchProfitability: %w", err)
	}
	defer rows.Close()

	var items []accounting.BatchProfitItem
	var totalMargin float64
	for rows.Next() {
		var br batchRow
		if err := rows.StructScan(&br); err != nil {
			return nil, fmt.Errorf("scan batch row: %w", err)
		}
		profit := br.Revenue - br.Expense - br.Commission
		marginPct := 0.0
		if br.Revenue > 0 {
			marginPct = profit / br.Revenue * 100
		}
		items = append(items, accounting.BatchProfitItem{
			BatchID:    br.BatchID,
			BatchCode:  br.BatchCode,
			CourseName: br.CourseName,
			Revenue:    br.Revenue,
			Expense:    br.Expense,
			Commission: br.Commission,
			Profit:     profit,
			MarginPct:  marginPct,
		})
		totalMargin += marginPct
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("batch rows error: %w", err)
	}

	avgMargin := 0.0
	if len(items) > 0 {
		avgMargin = totalMargin / float64(len(items))
	}

	if sort == "" {
		sort = "top"
	}

	return &accounting.BatchProfitResult{
		Items:     items,
		AvgMargin: avgMargin,
		Sort:      sort,
	}, nil
}

// GetCashForecast returns current cash position and forward-looking monthly projections.
func (r *AccountingAnalysisRepository) GetCashForecast(ctx context.Context, months int, branchID string) (*accounting.CashForecastResult, error) {
	if months <= 0 {
		months = 3
	}

	// Current cash position
	var currentCash float64
	err := r.db.QueryRowxContext(ctx, `
		SELECT COALESCE(SUM(CASE WHEN transaction_type='income' THEN amount ELSE -amount END), 0) AS cash
		FROM accounting_transactions
		WHERE status = 'completed'
		  AND transaction_type IN ('income', 'expense')
	`).Scan(&currentCash)
	if err != nil {
		return nil, fmt.Errorf("GetCashForecast current cash: %w", err)
	}

	// Upcoming pending invoices (projected inflows)
	type upcomingInvoice struct {
		DueDate     string  `db:"due_date"`
		Description string  `db:"description"`
		Amount      float64 `db:"amount"`
		Status      string  `db:"status"`
	}

	invRows, err := r.db.QueryxContext(ctx, `
		SELECT
			COALESCE(TO_CHAR(due_date, 'YYYY-MM-DD'), TO_CHAR(created_at + INTERVAL '30 days', 'YYYY-MM-DD')) AS due_date,
			COALESCE(invoice_number, 'Invoice') AS description,
			amount,
			status
		FROM accounting_invoices
		WHERE status IN ('sent', 'overdue', 'draft')
		  AND (due_date IS NULL OR due_date <= NOW() + INTERVAL '30 days')
		ORDER BY due_date
		LIMIT 20
	`)
	if err != nil {
		return nil, fmt.Errorf("GetCashForecast invoices: %w", err)
	}
	defer invRows.Close()

	var upcomingEvents []accounting.CashEvent
	for invRows.Next() {
		var inv upcomingInvoice
		if err := invRows.StructScan(&inv); err != nil {
			continue
		}
		status := "projected"
		if inv.Status == "overdue" {
			status = "projected"
		}
		upcomingEvents = append(upcomingEvents, accounting.CashEvent{
			Date:        inv.DueDate,
			EventType:   "inflow",
			Description: inv.Description,
			Amount:      inv.Amount,
			Status:      status,
		})
	}

	// Build monthly projections using average past months as baseline
	type avgMonthly struct {
		AvgInflow  float64 `db:"avg_inflow"`
		AvgOutflow float64 `db:"avg_outflow"`
	}

	var avg avgMonthly
	err = r.db.QueryRowxContext(ctx, `
		SELECT
			COALESCE(AVG(CASE WHEN transaction_type='income' THEN monthly_total ELSE NULL END), 0) AS avg_inflow,
			COALESCE(AVG(CASE WHEN transaction_type='expense' THEN monthly_total ELSE NULL END), 0) AS avg_outflow
		FROM (
			SELECT
				transaction_type,
				TO_CHAR(transaction_date, 'YYYY-MM') AS month,
				SUM(amount) AS monthly_total
			FROM accounting_transactions
			WHERE status = 'completed'
			  AND transaction_date >= NOW() - INTERVAL '6 months'
			GROUP BY transaction_type, TO_CHAR(transaction_date, 'YYYY-MM')
		) sub
	`).StructScan(&avg)
	if err != nil {
		return nil, fmt.Errorf("GetCashForecast avg monthly: %w", err)
	}

	var forecastMonths []accounting.CashForecastMonth
	openingCash := currentCash
	now := time.Now()
	for i := 0; i < months; i++ {
		t := now.AddDate(0, i+1, 0)
		monthLabel := fmt.Sprintf("%04d-%02d", t.Year(), int(t.Month()))
		closingCash := openingCash + avg.AvgInflow - avg.AvgOutflow
		forecastMonths = append(forecastMonths, accounting.CashForecastMonth{
			Month:       monthLabel,
			OpeningCash: openingCash,
			Inflow:      avg.AvgInflow,
			Outflow:     avg.AvgOutflow,
			ClosingCash: closingCash,
		})
		openingCash = closingCash
	}

	return &accounting.CashForecastResult{
		CurrentCash:    currentCash,
		Months:         forecastMonths,
		UpcomingEvents: upcomingEvents,
	}, nil
}

// GetAlerts returns financial alerts such as overdue invoices and negative-margin batches.
func (r *AccountingAnalysisRepository) GetAlerts(ctx context.Context) ([]*accounting.FinancialAlert, error) {
	var alerts []*accounting.FinancialAlert

	// Overdue invoices
	type overdueResult struct {
		Count int     `db:"cnt"`
		Total float64 `db:"total"`
	}
	var od overdueResult
	if err := r.db.QueryRowxContext(ctx, `
		SELECT COUNT(*) AS cnt, COALESCE(SUM(amount), 0) AS total
		FROM accounting_invoices
		WHERE status = 'overdue'
	`).StructScan(&od); err == nil && od.Count > 0 {
		alerts = append(alerts, &accounting.FinancialAlert{
			Level:   "warning",
			Code:    "overdue_invoices",
			Message: fmt.Sprintf("%d invoice melewati jatuh tempo", od.Count),
			Count:   od.Count,
			Amount:  od.Total,
		})
	}

	// Sent (unpaid) invoices
	type sentResult struct {
		Count int     `db:"cnt"`
		Total float64 `db:"total"`
	}
	var sent sentResult
	if err := r.db.QueryRowxContext(ctx, `
		SELECT COUNT(*) AS cnt, COALESCE(SUM(amount), 0) AS total
		FROM accounting_invoices
		WHERE status = 'sent'
	`).StructScan(&sent); err == nil && sent.Count > 0 {
		alerts = append(alerts, &accounting.FinancialAlert{
			Level:   "info",
			Code:    "pending_invoices",
			Message: fmt.Sprintf("%d invoice belum dibayar", sent.Count),
			Count:   sent.Count,
			Amount:  sent.Total,
		})
	}

	// Negative margin batches this month
	now := time.Now()
	monthStart := fmt.Sprintf("%04d-%02d-01", now.Year(), int(now.Month()))
	nextMonth := int(now.Month()) + 1
	nextYear := now.Year()
	if nextMonth > 12 {
		nextMonth = 1
		nextYear++
	}
	monthEnd := fmt.Sprintf("%04d-%02d-01", nextYear, nextMonth)

	type negBatch struct {
		Count int `db:"cnt"`
	}
	var nb negBatch
	if err := r.db.QueryRowxContext(ctx, `
		WITH batch_totals AS (
			SELECT
				related_entity_id,
				SUM(CASE WHEN transaction_type='income' THEN amount ELSE 0 END) AS revenue,
				SUM(CASE WHEN transaction_type='expense' THEN amount ELSE 0 END) AS expense
			FROM accounting_transactions
			WHERE related_entity_type = 'batch'
			  AND related_entity_id IS NOT NULL
			  AND status = 'completed'
			  AND transaction_date >= $1
			  AND transaction_date < $2
			GROUP BY related_entity_id
		)
		SELECT COUNT(*) AS cnt
		FROM batch_totals
		WHERE revenue > 0 AND (revenue - expense) < 0
	`, monthStart, monthEnd).StructScan(&nb); err == nil && nb.Count > 0 {
		alerts = append(alerts, &accounting.FinancialAlert{
			Level:   "warning",
			Code:    "negative_margin_batches",
			Message: fmt.Sprintf("%d batch mengalami kerugian bulan ini", nb.Count),
			Count:   nb.Count,
		})
	}

	if len(alerts) == 0 {
		alerts = append(alerts, &accounting.FinancialAlert{
			Level:   "success",
			Code:    "all_clear",
			Message: "Tidak ada peringatan keuangan",
		})
	}

	return alerts, nil
}

// GetSuggestions returns actionable financial suggestions based on current data.
func (r *AccountingAnalysisRepository) GetSuggestions(ctx context.Context) ([]*accounting.FinancialSuggestion, error) {
	var suggestions []*accounting.FinancialSuggestion

	// Check overdue invoices
	type overdueResult struct {
		Count int     `db:"cnt"`
		Total float64 `db:"total"`
	}
	var od overdueResult
	if err := r.db.QueryRowxContext(ctx, `
		SELECT COUNT(*) AS cnt, COALESCE(SUM(amount), 0) AS total
		FROM accounting_invoices
		WHERE status = 'overdue'
	`).StructScan(&od); err == nil && od.Count > 0 {
		suggestions = append(suggestions, &accounting.FinancialSuggestion{
			Icon:    "warning",
			Message: fmt.Sprintf("Tindak lanjuti %d invoice yang sudah jatuh tempo", od.Count),
			Amount:  od.Total,
			Detail:  "Hubungi siswa untuk menyelesaikan pembayaran yang tertunggak",
		})
	}

	// Top revenue category
	type topCat struct {
		Category string  `db:"category"`
		Revenue  float64 `db:"revenue"`
	}
	var tc topCat
	if err := r.db.QueryRowxContext(ctx, `
		SELECT
			COALESCE(NULLIF(TRIM(category), ''), 'other') AS category,
			COALESCE(SUM(amount), 0) AS revenue
		FROM accounting_transactions
		WHERE transaction_type = 'income'
		  AND status = 'completed'
		  AND transaction_date >= NOW() - INTERVAL '3 months'
		GROUP BY COALESCE(NULLIF(TRIM(category), ''), 'other')
		ORDER BY revenue DESC
		LIMIT 1
	`).StructScan(&tc); err == nil && tc.Revenue > 0 {
		suggestions = append(suggestions, &accounting.FinancialSuggestion{
			Icon:    "trending_up",
			Message: fmt.Sprintf("Kategori '%s' adalah sumber pendapatan terbesar", tc.Category),
			Amount:  tc.Revenue,
			Detail:  "Pertimbangkan untuk meningkatkan kapasitas atau frekuensi kelas ini",
		})
	}

	// Batches with low or negative margins
	type lowMarginBatch struct {
		Count int `db:"cnt"`
	}
	var lm lowMarginBatch
	if err := r.db.QueryRowxContext(ctx, `
		WITH batch_totals AS (
			SELECT
				related_entity_id,
				SUM(CASE WHEN transaction_type='income' THEN amount ELSE 0 END) AS revenue,
				SUM(CASE WHEN transaction_type='expense' THEN amount ELSE 0 END) AS expense
			FROM accounting_transactions
			WHERE related_entity_type = 'batch'
			  AND related_entity_id IS NOT NULL
			  AND status = 'completed'
			  AND transaction_date >= NOW() - INTERVAL '3 months'
			GROUP BY related_entity_id
		)
		SELECT COUNT(*) AS cnt
		FROM batch_totals
		WHERE revenue > 0 AND (revenue - expense) / revenue * 100 < 10
	`).StructScan(&lm); err == nil && lm.Count > 0 {
		suggestions = append(suggestions, &accounting.FinancialSuggestion{
			Icon:    "edit",
			Message: fmt.Sprintf("Tinjau harga untuk %d batch dengan margin rendah", lm.Count),
			Detail:  "Beberapa batch memiliki margin di bawah 10%. Pertimbangkan penyesuaian harga atau efisiensi biaya.",
		})
	}

	if len(suggestions) == 0 {
		suggestions = append(suggestions, &accounting.FinancialSuggestion{
			Icon:    "check_circle",
			Message: "Kondisi keuangan dalam keadaan baik",
			Detail:  "Tidak ada tindakan mendesak yang diperlukan saat ini",
		})
	}

	return suggestions, nil
}
