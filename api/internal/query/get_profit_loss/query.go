package get_profit_loss

// GetProfitLossQuery retrieves the profit & loss statement for a given period.
type GetProfitLossQuery struct {
	From     string // "YYYY-MM-DD"
	To       string // "YYYY-MM-DD"
	BranchID string // "" = consolidated
}
