package update_mou

type UpdateMOUCommand struct {
	ID             string `validate:"required"`
	DocumentNumber string
	Title          string
	StartDate      string
	EndDate        string
	Status         string
	DocumentURL    string
	Notes          string
}
