package create_delegation

type CreateDelegationCommand struct {
	Title            string `validate:"required"`
	Type             string
	Description      string
	AssignedToID     string
	AssignedToName   string
	AssignedByID     string
	AssignedByName   string
	Priority         string
	Deadline         string
	LinkedEntityID   string
	LinkedEntityType string
}
