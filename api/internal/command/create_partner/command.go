package create_partner

import "github.com/google/uuid"

type CreatePartnerCommand struct {
	Name          string     `validate:"required"`
	Industry      string
	Status        string
	GroupID       *uuid.UUID
	ContactEmail  string
	ContactPhone  string
	ContactPerson string
	Website       string
	Address       string
	Notes         string
}
