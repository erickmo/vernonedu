package create_payable

import "github.com/google/uuid"

type CreatePayableCommand struct {
	Type          string
	RecipientID   uuid.UUID
	RecipientName string
	BatchID       *uuid.UUID
	Amount        int64
	BranchID      *uuid.UUID
	Notes         string
}

func (c *CreatePayableCommand) CommandName() string { return "CreatePayable" }
