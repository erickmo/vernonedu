package grant_app_access

import "github.com/google/uuid"

type GrantAppAccessCommand struct {
	StudentID uuid.UUID `validate:"required"`
	AppName   string    `validate:"required"`
	BatchID   uuid.UUID `validate:"required"`
}
