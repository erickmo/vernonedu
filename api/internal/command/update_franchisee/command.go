package update_franchisee

import "github.com/google/uuid"

type UpdateFranchiseeCommand struct {
	ID         uuid.UUID `validate:"required"`
	Name       string    `validate:"required"`
	BranchName string    `validate:"required"`
	Location   string
	Contact    string
	Status     string `validate:"required"`
}
