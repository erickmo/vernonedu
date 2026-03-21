package create_building

type CreateBuildingCommand struct {
	Name        string `validate:"required"`
	Address     string
	Description string
}
