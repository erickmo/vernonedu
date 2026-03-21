package get_general_ledger

// GetGeneralLedgerQuery retrieves the general ledger for one account.
type GetGeneralLedgerQuery struct {
	AccountCode string // required
	From        string // "YYYY-MM-DD"
	To          string // "YYYY-MM-DD"
	BranchID    string // "" = consolidated
}
