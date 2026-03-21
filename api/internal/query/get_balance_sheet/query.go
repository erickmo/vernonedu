package get_balance_sheet

// GetBalanceSheetQuery retrieves the balance sheet for a given period.
type GetBalanceSheetQuery struct {
	From     string // "YYYY-MM-DD"
	To       string // "YYYY-MM-DD"
	BranchID string // "" = consolidated
}
