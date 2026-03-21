package get_cash_flow

// GetCashFlowQuery retrieves the cash flow statement for a given period.
type GetCashFlowQuery struct {
	From     string // "YYYY-MM-DD"
	To       string // "YYYY-MM-DD"
	BranchID string // "" = consolidated
}
