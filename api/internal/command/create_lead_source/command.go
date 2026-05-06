package create_lead_source

type CreateLeadSourceCommand struct {
	Name string `validate:"required"`
}
