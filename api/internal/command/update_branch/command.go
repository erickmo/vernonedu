package update_branch

import "github.com/google/uuid"

// UpdateBranchCommand updates a company branch's details.
type UpdateBranchCommand struct {
	ID           uuid.UUID `validate:"required"`
	Name         string    `validate:"required"`
	Address      string
	City         string
	Region       string
	ContactName  string
	ContactPhone string
	Status       string `validate:"required,oneof=active inactive"`
}
