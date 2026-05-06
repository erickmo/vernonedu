package update_lead

import "github.com/google/uuid"

type UpdateLeadCommand struct {
	ID       uuid.UUID  `validate:"required"`
	Name     string     `validate:"required"`
	Email    string
	Phone    string     `validate:"required"`
	SourceID *uuid.UUID
	Notes    string
	Status   string
	PicID    *uuid.UUID
}
