package get_revenue_analysis

type GetRevenueAnalysisQuery struct {
	Period   string
	Month    int
	Year     int
	BranchID string
	GroupBy  string // course_type, branch, month
}
