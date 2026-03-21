package create_lead

import "github.com/google/uuid"

type CreateLeadCommand struct {
	Name     string     `validate:"required"`
	Email    string
	Phone    string
	Interest string
	Source   string
	Notes    string
	PicID    *uuid.UUID
}
