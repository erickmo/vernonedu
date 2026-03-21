package delete_partner

type DeletePartnerCommand struct {
	ID string `validate:"required"`
}
