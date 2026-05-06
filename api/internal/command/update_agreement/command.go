package update_agreement

import "github.com/google/uuid"

type UpdateAgreementCommand struct {
	ID                uuid.UUID `validate:"required"`
	BuyInFee          float64
	MonthlyRoyalty    float64
	RevenueRoyaltyPct float64 `validate:"min=0,max=100"`
	StartDate         string  `validate:"required"`
	EndDate           string
	Status            string `validate:"required"`
}
