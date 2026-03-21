package create_branch

type CreateBranchCommand struct {
	Name         string `validate:"required"`
	City         string
	Address      string
	Region       string
	ContactName  string
	ContactPhone string
	Status       string // "active" | "inactive"; defaults to "active"
	PartnerID    string
	IsActive     bool
}
