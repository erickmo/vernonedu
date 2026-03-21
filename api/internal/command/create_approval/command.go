package create_approval

import "github.com/google/uuid"

type StepInput struct {
	ApproverID   uuid.UUID `validate:"required"`
	ApproverRole string    `validate:"required"`
}

type CreateApprovalCommand struct {
	Type        string      `validate:"required"`
	EntityType  string      `validate:"required"`
	EntityID    uuid.UUID   `validate:"required"`
	InitiatorID uuid.UUID   `validate:"required"`
	Reason      string
	Steps       []StepInput `validate:"required,min=1"`
}
