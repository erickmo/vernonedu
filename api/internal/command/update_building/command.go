package update_building

import "github.com/google/uuid"

type UpdateBuildingCommand struct {
	ID          uuid.UUID  `validate:"required"`
	Name        string     `validate:"required"`
	Address     string
	Description string
	Ownership   string     `validate:"required"`
	PartnerID   *uuid.UUID
}
