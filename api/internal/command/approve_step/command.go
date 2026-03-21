package approve_step

import "github.com/google/uuid"

type ApproveStepCommand struct {
	ApprovalID uuid.UUID `validate:"required"`
	ApproverID uuid.UUID `validate:"required"`
	Comment    string
}
