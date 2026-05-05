package delete_calendar_event

import "github.com/google/uuid"

type DeleteCalendarEventCommand struct {
	ID uuid.UUID `validate:"required"`
}
