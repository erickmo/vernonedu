package create_mou

type CreateMOUCommand struct {
	PartnerIDStr   string `validate:"required"`
	DocumentNumber string `validate:"required"`
	Title          string
	StartDate      string `validate:"required"`
	EndDate        string `validate:"required"`
	Status         string
	DocumentURL    string
	Notes          string
}
