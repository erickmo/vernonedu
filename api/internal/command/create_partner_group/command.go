package create_partner_group

type CreatePartnerGroupCommand struct {
	Name        string `validate:"required"`
	Description string
}
