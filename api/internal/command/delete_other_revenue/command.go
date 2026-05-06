package delete_other_revenue

import "github.com/google/uuid"

type DeleteOtherRevenueCommand struct {
	ID uuid.UUID `validate:"required"`
}
