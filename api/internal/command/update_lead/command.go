package update_lead

import "github.com/google/uuid"

type UpdateLeadCommand struct {
	ID       uuid.UUID  `validate:"required"`
	Name     string     `validate:"required"`
	Email    string
	Phone    string
	Interest string
	Source   string
	Notes    string
	Status   string
	PicID    *uuid.UUID
}
