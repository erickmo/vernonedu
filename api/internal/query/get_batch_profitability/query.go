package get_batch_profitability

type GetBatchProfitabilityQuery struct {
	Period   string
	Month    int
	Year     int
	BranchID string
	Sort     string // top, bottom
	Limit    int
}
