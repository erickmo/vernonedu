package platform

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// facilitatorRole is the attendee role used to identify the class facilitator
// when assembling the class.reminder payload.
const facilitatorRole = "facilitator"

// ScanClassReminders finds class_session events firing in ~1 hour, marks each
// as reminded (idempotent guard via UPDATE ... WHERE reminder_fired_at IS NULL),
// resolves attendees, and publishes a class.reminder event for downstream
// notification fan-out.
//
// Worker calls this once per minute. The repository window is 5 minutes wide
// so a missed tick still picks up events on the next call.
func (s *Service) ScanClassReminders(ctx context.Context) error {
	candidates, err := s.repo.ListEventsNeedingReminder(ctx)
	if err != nil {
		return err
	}
	for _, e := range candidates {
		s.processReminder(ctx, e)
	}
	return nil
}

// processReminder marks the event reminded and publishes the class.reminder
// event. Errors are logged but do not abort the scan batch.
func (s *Service) processReminder(ctx context.Context, e *CalendarEvent) {
	marked, err := s.repo.MarkReminderFired(ctx, e.ID)
	if err != nil {
		s.log.Error("mark reminder fired",
			zap.String("event_id", e.ID.String()), zap.Error(err))
		return
	}
	if !marked {
		// Raced with another scanner — already fired by someone else.
		return
	}

	attendees, err := s.repo.ListCalendarAttendeesByEvent(ctx, e.ID)
	if err != nil {
		s.log.Error("list attendees for reminder",
			zap.String("event_id", e.ID.String()), zap.Error(err))
		return
	}

	payload := buildClassReminderPayload(e, attendees)
	if s.bus == nil {
		return
	}
	if err := s.bus.Publish(ctx, events.Event{
		Type:    events.ClassReminder,
		Payload: payload,
	}); err != nil {
		s.log.Error("publish class.reminder",
			zap.String("event_id", e.ID.String()), zap.Error(err))
	}
}

// buildClassReminderPayload assembles the cross-domain payload from the
// calendar event row and its attendee list.
func buildClassReminderPayload(e *CalendarEvent, attendees []*CalendarAttendee) events.ClassReminderPayload {
	attendeeIDs := make([]uuid.UUID, 0, len(attendees))
	var facilitatorID uuid.UUID
	for _, a := range attendees {
		attendeeIDs = append(attendeeIDs, a.UserID)
		if a.Role == facilitatorRole && facilitatorID == uuid.Nil {
			facilitatorID = a.UserID
		}
	}

	var classID uuid.UUID
	if e.SourceID != nil {
		classID = *e.SourceID
	}

	return events.ClassReminderPayload{
		ClassID:       classID,
		FacilitatorID: facilitatorID,
		AttendeeIDs:   attendeeIDs,
		ClassTitle:    e.Title,
		StartAt:       e.StartAt.Format(time.RFC3339),
	}
}
