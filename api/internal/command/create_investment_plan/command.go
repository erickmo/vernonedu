package create_investment_plan

type CreateInvestmentPlanCommand struct {
	Title       string  `validate:"required"`
	Category    string
	ProposedBy  string
	Amount      int64
	ExpectedROI float64
	Status      string
	Notes       string
}
