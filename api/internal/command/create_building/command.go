package create_building

import "github.com/google/uuid"

type CreateBuildingCommand struct {
	Name        string     `validate:"required"`
	Address     string
	Description string
	Ownership   string     `validate:"required"`
	PartnerID   *uuid.UUID
	ResultID    uuid.UUID
}
