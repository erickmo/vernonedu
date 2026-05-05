package create_building

import "github.com/google/uuid"

type CreateBuildingCommand struct {
	Name        string    `validate:"required"`
	Address     string
	Description string
	ResultID    uuid.UUID
}
