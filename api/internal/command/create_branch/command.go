package create_branch

type CreateBranchCommand struct {
	Name      string `validate:"required"`
	City      string
	Address   string
	PartnerID string
	IsActive  bool
}
