package create_royalty_payment

import "github.com/google/uuid"

type CreateRoyaltyPaymentCommand struct {
	FranchiseeID uuid.UUID `validate:"required"`
	Period       string    `validate:"required"`
	GrossRevenue float64
	RecordedBy   *uuid.UUID
}
