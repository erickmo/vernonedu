package platform

import (
	"context"

	"github.com/google/uuid"

	ical "github.com/arran4/golang-ical"
)

const (
	icalProductID = "-//VernonEdu//Calendar 1.0//EN"
)

// ExportICalForUser returns RFC 5545 iCalendar bytes containing all events
// where the user is the creator or an attendee.
func (s *Service) ExportICalForUser(ctx context.Context, userID uuid.UUID) ([]byte, error) {
	evts, err := s.repo.ListCalendarEventsByUser(ctx, userID)
	if err != nil {
		return nil, err
	}
	cal := newICalBase()
	for _, e := range evts {
		addEvent(cal, e)
	}
	return []byte(cal.Serialize()), nil
}

// ExportSingleEvent returns RFC 5545 iCalendar bytes for one event.
func (s *Service) ExportSingleEvent(ctx context.Context, eventID uuid.UUID) ([]byte, error) {
	e, err := s.repo.GetCalendarEvent(ctx, eventID)
	if err != nil {
		return nil, err
	}
	cal := newICalBase()
	addEvent(cal, e)
	return []byte(cal.Serialize()), nil
}

func newICalBase() *ical.Calendar {
	cal := ical.NewCalendar()
	cal.SetMethod(ical.MethodPublish)
	cal.SetProductId(icalProductID)
	return cal
}

func addEvent(cal *ical.Calendar, e *CalendarEvent) {
	ev := cal.AddEvent(e.ID.String())
	ev.SetSummary(e.Title)
	if e.Description != nil {
		ev.SetDescription(*e.Description)
	}
	ev.SetStartAt(e.StartAt)
	ev.SetEndAt(e.EndAt)
	if e.Location != nil {
		ev.SetLocation(*e.Location)
	}
	if e.Rrule != nil && *e.Rrule != "" {
		ev.AddRrule(*e.Rrule)
	}
}
