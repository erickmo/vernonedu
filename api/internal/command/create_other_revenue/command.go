package create_other_revenue

import "github.com/google/uuid"

type CreateOtherRevenueCommand struct {
	FranchiseeID uuid.UUID `validate:"required"`
	Label        string    `validate:"required"`
	Amount       float64   `validate:"required"`
	RevenueDate  string    `validate:"required"`
	AddedBy      *uuid.UUID
}
