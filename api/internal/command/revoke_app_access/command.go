package revoke_app_access

import "github.com/google/uuid"

type RevokeAppAccessCommand struct {
	StudentID uuid.UUID `validate:"required"`
	BatchID   uuid.UUID `validate:"required"`
	Reason    string    `validate:"required"`
}

type RevokeAllBatchAccessCommand struct {
	BatchID uuid.UUID `validate:"required"`
	Reason  string    `validate:"required"`
}
