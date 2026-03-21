package create_lead

type CreateLeadCommand struct {
	Name     string `validate:"required"`
	Email    string
	Phone    string
	Interest string
	Source   string
	Notes    string
}
