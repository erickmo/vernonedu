package get_financial_ratios

type GetFinancialRatiosQuery struct {
	Period     string
	Month      int
	Year       int
	BranchID   string
	Comparison string // prev_month, prev_quarter, prev_year
}
