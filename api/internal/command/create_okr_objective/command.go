package create_okr_objective

type CreateOkrObjectiveCommand struct {
	Title     string `validate:"required"`
	OwnerID   string
	OwnerName string
	Period    string
	Level     string
	Status    string
}
