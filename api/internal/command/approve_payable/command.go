package approve_payable

import "github.com/google/uuid"

type ApprovePayableCommand struct {
	ID uuid.UUID
}

func (c *ApprovePayableCommand) CommandName() string { return "ApprovePayable" }
