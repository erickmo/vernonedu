package mark_royalty_paid

import "github.com/google/uuid"

type MarkRoyaltyPaidCommand struct {
	RecordID uuid.UUID `validate:"required"`
}
