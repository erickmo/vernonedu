package create_holiday

// CreateHolidayCommand creates a new holiday entry.
type CreateHolidayCommand struct {
	Date string `validate:"required"` // RFC3339 date, e.g. "2026-08-17"
	Name string `validate:"required"`
}
