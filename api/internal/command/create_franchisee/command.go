package create_franchisee

import "github.com/google/uuid"

type CreateFranchiseeCommand struct {
	Name       string `validate:"required"`
	BranchName string `validate:"required"`
	Location   string
	Contact    string
	Status     string
	CreatedBy  *uuid.UUID
}
