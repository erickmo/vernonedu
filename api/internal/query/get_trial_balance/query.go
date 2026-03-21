package get_trial_balance

// GetTrialBalanceQuery retrieves the trial balance for a given period.
type GetTrialBalanceQuery struct {
	From     string // "YYYY-MM-DD"
	To       string // "YYYY-MM-DD"
	BranchID string // "" = consolidated
}
