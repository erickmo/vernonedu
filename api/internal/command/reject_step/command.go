package reject_step

import "github.com/google/uuid"

type RejectStepCommand struct {
	ApprovalID uuid.UUID `validate:"required"`
	ApproverID uuid.UUID `validate:"required"`
	Comment    string    `validate:"required"`
}
