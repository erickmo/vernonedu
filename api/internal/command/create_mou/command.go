package create_mou

type CreateMOUCommand struct {
	PartnerIDStr   string `validate:"required"`
	DocumentNumber string `validate:"required"`
	StartDate      string `validate:"required"`
	EndDate        string `validate:"required"`
	Notes          string
}
