package accounting

import "context"

// --- Params ---

type PeriodParams struct {
	Period     string // monthly, quarterly, yearly, custom
	StartDate  string // YYYY-MM-DD, used when period=custom
	EndDate    string // YYYY-MM-DD
	Month      int    // 1-12, used when period=monthly
	Year       int    // YYYY
	BranchID   string // optional
	Comparison string // prev_month, prev_quarter, prev_year
}

// --- Financial Ratios ---

type RatioMetric struct {
	Current   float64 `json:"current"`
	Previous  float64 `json:"previous"`
	Change    float64 `json:"change"`     // absolute change
	ChangePct float64 `json:"change_pct"` // percentage change
	Trend     string  `json:"trend"`      // up, down, flat
}

type FinancialRatiosResult struct {
	ProfitMargin          RatioMetric `json:"profit_margin"`
	ExpenseRatio          RatioMetric `json:"expense_ratio"`
	RevenuePerStudent     RatioMetric `json:"revenue_per_student"`
	CostPerStudent        RatioMetric `json:"cost_per_student"`
	AvgBatchProfitability RatioMetric `json:"avg_batch_profitability"`
	CollectionRate        RatioMetric `json:"collection_rate"`
	DaysSalesOutstanding  RatioMetric `json:"days_sales_outstanding"`
	RevenueGrowthRate     RatioMetric `json:"revenue_growth_rate"`
}

// --- Revenue Analysis ---

type RevenueByGroup struct {
	GroupKey    string  `json:"group_key"` // course type name, branch name, or YYYY-MM
	Revenue     float64 `json:"revenue"`
	PctOfTotal  float64 `json:"pct_of_total"`
	BatchCount  int     `json:"batch_count"`
	AvgPerBatch float64 `json:"avg_per_batch"`
	Trend       string  `json:"trend"` // up, down, flat
}

type MonthlyRevenueTrend struct {
	Month   string  `json:"month"` // YYYY-MM
	Total   float64 `json:"total"`
	Regular float64 `json:"regular"`
	Career  float64 `json:"career"`
	Inhouse float64 `json:"inhouse"`
	Collab  float64 `json:"collab"`
	Cert    float64 `json:"cert"`
}

type RevenueAnalysisResult struct {
	MonthlyTrend []MonthlyRevenueTrend `json:"monthly_trend"`
	ByGroup      []RevenueByGroup      `json:"by_group"`
	TotalRevenue float64               `json:"total_revenue"`
	GroupBy      string                `json:"group_by"`
}

// --- Cost Analysis ---

type CostByGroup struct {
	Category   string  `json:"category"`
	Amount     float64 `json:"amount"`
	PctOfTotal float64 `json:"pct_of_total"`
	VsPrevious float64 `json:"vs_previous"` // absolute diff
	Trend      string  `json:"trend"`
}

type MonthlyCostTrend struct {
	Month       string  `json:"month"`
	Total       float64 `json:"total"`
	Facilitator float64 `json:"facilitator"`
	Commission  float64 `json:"commission"`
	Operational float64 `json:"operational"`
	Marketing   float64 `json:"marketing"`
	Other       float64 `json:"other"`
}

type CostAnalysisResult struct {
	MonthlyTrend []MonthlyCostTrend `json:"monthly_trend"`
	ByCategory   []CostByGroup      `json:"by_category"`
	TotalCost    float64            `json:"total_cost"`
}

// --- Batch Profitability ---

type BatchProfitItem struct {
	BatchID    string  `json:"batch_id"`
	BatchCode  string  `json:"batch_code"`
	CourseName string  `json:"course_name"`
	Revenue    float64 `json:"revenue"`
	Expense    float64 `json:"expense"`
	Commission float64 `json:"commission"`
	Profit     float64 `json:"profit"`
	MarginPct  float64 `json:"margin_pct"`
}

type BatchProfitResult struct {
	Items     []BatchProfitItem `json:"items"`
	AvgMargin float64           `json:"avg_margin"`
	Sort      string            `json:"sort"` // top, bottom
}

// --- Cash Forecast ---

type CashEvent struct {
	Date        string  `json:"date"`
	EventType   string  `json:"event_type"` // inflow, outflow
	Description string  `json:"description"`
	Amount      float64 `json:"amount"`
	Status      string  `json:"status"` // confirmed, projected
}

type CashForecastMonth struct {
	Month       string  `json:"month"`
	OpeningCash float64 `json:"opening_cash"`
	Inflow      float64 `json:"inflow"`
	Outflow     float64 `json:"outflow"`
	ClosingCash float64 `json:"closing_cash"`
}

type CashForecastResult struct {
	CurrentCash    float64             `json:"current_cash"`
	Months         []CashForecastMonth `json:"months"`
	UpcomingEvents []CashEvent         `json:"upcoming_events"`
}

// --- Alerts ---

type FinancialAlert struct {
	Level   string  `json:"level"` // warning, info, success
	Code    string  `json:"code"`
	Message string  `json:"message"`
	Count   int     `json:"count,omitempty"`
	Amount  float64 `json:"amount,omitempty"`
}

// --- Suggestions ---

type FinancialSuggestion struct {
	Icon    string  `json:"icon"` // emoji or icon key
	Message string  `json:"message"`
	Amount  float64 `json:"amount,omitempty"`
	Detail  string  `json:"detail,omitempty"`
}

// --- Repository Interface ---

type AnalysisReadRepository interface {
	GetFinancialRatios(ctx context.Context, params PeriodParams) (*FinancialRatiosResult, error)
	GetRevenueAnalysis(ctx context.Context, params PeriodParams, groupBy string) (*RevenueAnalysisResult, error)
	GetCostAnalysis(ctx context.Context, params PeriodParams, groupBy string) (*CostAnalysisResult, error)
	GetBatchProfitability(ctx context.Context, params PeriodParams, sort string, limit int) (*BatchProfitResult, error)
	GetCashForecast(ctx context.Context, months int, branchID string) (*CashForecastResult, error)
	GetAlerts(ctx context.Context) ([]*FinancialAlert, error)
	GetSuggestions(ctx context.Context) ([]*FinancialSuggestion, error)
}
