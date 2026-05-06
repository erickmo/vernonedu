package create_lead

import "github.com/google/uuid"

type CreateLeadCommand struct {
	Name     string     `validate:"required"`
	Email    string
	Phone    string     `validate:"required"`
	SourceID *uuid.UUID
	Notes    string
	PicID    *uuid.UUID
}
