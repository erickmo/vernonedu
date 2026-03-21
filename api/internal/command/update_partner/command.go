package update_partner

import "github.com/google/uuid"

type UpdatePartnerCommand struct {
	ID            string `validate:"required"`
	Name          string
	Industry      string
	Status        string
	GroupID       *uuid.UUID
	ContactEmail  string
	ContactPhone  string
	ContactPerson string
	Website       string
	Address       string
	LogoURL       string
	Notes         string
}
