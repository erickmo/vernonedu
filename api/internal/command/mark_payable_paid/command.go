package mark_payable_paid

import "github.com/google/uuid"

type MarkPayablePaidCommand struct {
	ID           uuid.UUID
	PaymentProof string
	AccountCode  string // cash/bank account code, defaults to "1101" (Kas)
}

func (c *MarkPayablePaidCommand) CommandName() string { return "MarkPayablePaid" }
