package cancel_approval

import "github.com/google/uuid"

type CancelApprovalCommand struct {
	ApprovalID  uuid.UUID `validate:"required"`
	InitiatorID uuid.UUID `validate:"required"`
}
