package delete_holiday

import "github.com/google/uuid"

// DeleteHolidayCommand removes a holiday by ID.
type DeleteHolidayCommand struct {
	ID uuid.UUID `validate:"required"`
}
