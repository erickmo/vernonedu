package create_delegation

type CreateDelegationCommand struct {
	Title            string `validate:"required"`
	Type             string `validate:"required"`
	Description      string
	RequestedByID    string `validate:"required"`
	RequestedByName  string
	AssignedToID     string
	AssignedToName   string
	AssignedToRole   string
	DueDate          string // RFC3339 or empty
	Priority         string `validate:"required"`
	LinkedEntityType string
	LinkedEntityID   string
	Notes            string
}
