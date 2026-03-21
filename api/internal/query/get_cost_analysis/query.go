package get_cost_analysis

type GetCostAnalysisQuery struct {
	Period   string
	Month    int
	Year     int
	BranchID string
	GroupBy  string // category, month
}
