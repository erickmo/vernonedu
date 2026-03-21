package cancel_payable

import "github.com/google/uuid"

type CancelPayableCommand struct {
	ID uuid.UUID
}

func (c *CancelPayableCommand) CommandName() string { return "CancelPayable" }
