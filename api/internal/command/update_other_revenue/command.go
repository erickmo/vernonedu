package update_other_revenue

import "github.com/google/uuid"

type UpdateOtherRevenueCommand struct {
	ID          uuid.UUID `validate:"required"`
	Label       string    `validate:"required"`
	Amount      float64   `validate:"required"`
	RevenueDate string    `validate:"required"`
}
