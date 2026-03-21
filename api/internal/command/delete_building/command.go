package delete_building

import "github.com/google/uuid"

type DeleteBuildingCommand struct {
	ID uuid.UUID `validate:"required"`
}
