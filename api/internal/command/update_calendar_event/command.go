package update_calendar_event

type UpdateCalendarEventCommand struct {
	ID             string `validate:"required"`
	Title          string `validate:"required,min=1,max=255"`
	Description    string
	EventType      string `validate:"required,oneof=class_session staff_meeting admin_deadline payment_due facilitator_schedule partner_meeting"`
	StartAt        string `validate:"required"`
	EndAt          string `validate:"required"`
	IsAllDay       bool
	RecurrenceRule string
	Location       string
}
