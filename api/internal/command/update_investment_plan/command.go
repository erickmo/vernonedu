package update_investment_plan

type UpdateInvestmentPlanCommand struct {
	ID          string `validate:"required"`
	Title       string `validate:"required"`
	Category    string
	ProposedBy  string
	Amount      int64
	ExpectedROI float64
	ActualSpend int64
	Status      string
	ApprovedBy  string
	Notes       string
}
