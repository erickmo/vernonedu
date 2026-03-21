package update_partner_group

type UpdatePartnerGroupCommand struct {
	ID          string `validate:"required"`
	Name        string
	Description string
}
