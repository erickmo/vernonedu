package platform

import (
	"context"
	"fmt"

	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// Source-domain tags for auto-created calendar events.
const (
	calendarSourceCourse              = "course"
	calendarSourcePayment             = "payment"
	calendarSourcePartnershipMeeting  = "partnership_agreement"
	calendarRoleFacilitator           = "facilitator"
	calendarRoleAttendee              = "attendee"
	calendarPaymentDueTitleFmt        = "Payment due %s"
)

// logCalendarHandlerErr records a non-fatal handler failure without aborting the bus.
func (s *Service) logCalendarHandlerErr(eventType events.EventType, err error) {
	if err == nil {
		return
	}
	s.log.Warn("calendar handler error",
		zap.String("event", string(eventType)),
		zap.Error(err),
	)
}

// handleBatchCreated_Calendar materialises one class_session event per Class.
func (s *Service) handleBatchCreated_Calendar(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.BatchCreatedPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	for _, c := range p.Classes {
		var loc *string
		if c.Location != "" {
			l := c.Location
			loc = &l
		}
		batchID := p.BatchID
		_, err := s.CreateAutoEvent(ctx, CreateAutoEventInput{
			Title:        c.Title,
			EventType:    CalendarTypeClassSession,
			StartAt:      c.StartAt,
			EndAt:        c.EndAt,
			Location:     loc,
			SourceDomain: calendarSourceCourse,
			SourceID:     c.ClassID,
			BatchID:      &batchID,
		})
		s.logCalendarHandlerErr(evt.Type, err)
	}
	return nil
}

// handleClassFacilitatorAssigned adds the facilitator as attendee to the class_session.
func (s *Service) handleClassFacilitatorAssigned_Calendar(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.ClassFacilitatorAssignedPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	err := s.AddAttendeeBySource(ctx, calendarSourceCourse, p.ClassID, p.FacilitatorID, calendarRoleFacilitator)
	s.logCalendarHandlerErr(evt.Type, err)
	return nil
}

// handleClassRescheduled mutates start/end on the existing class_session event.
func (s *Service) handleClassRescheduled_Calendar(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.ClassRescheduledPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	err := s.UpdateEventTimes(ctx, calendarSourceCourse, p.ClassID, p.StartAt, p.EndAt)
	s.logCalendarHandlerErr(evt.Type, err)
	return nil
}

// handleClassCancelled removes the class_session event (attendees cascade via FK).
func (s *Service) handleClassCancelled_Calendar(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.ClassCancelledPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	err := s.DeleteEventBySource(ctx, calendarSourceCourse, p.ClassID)
	s.logCalendarHandlerErr(evt.Type, err)
	return nil
}

// handlePaymentTermDue_Calendar creates a one-off payment_due event for the student.
func (s *Service) handlePaymentTermDue_Calendar(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.PaymentTermDuePayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	// FindEventBySource → skip if already materialised (idempotent).
	existing, err := s.FindEventBySource(ctx, calendarSourcePayment, p.TermID)
	if err != nil {
		s.logCalendarHandlerErr(evt.Type, err)
		return nil
	}
	if existing != nil {
		return nil
	}
	due, parseErr := parseDueDate(p.DueDate)
	if parseErr != nil {
		s.logCalendarHandlerErr(evt.Type, parseErr)
		return nil
	}
	title := fmt.Sprintf(calendarPaymentDueTitleFmt, p.DueDate)
	_, err = s.CreateAutoEvent(ctx, CreateAutoEventInput{
		Title:        title,
		EventType:    CalendarTypePaymentDue,
		StartAt:      due,
		EndAt:        due.Add(paymentDueWindow),
		SourceDomain: calendarSourcePayment,
		SourceID:     p.TermID,
	})
	s.logCalendarHandlerErr(evt.Type, err)
	if err == nil {
		// Add the student as attendee so the event surfaces in their calendar.
		_ = s.AddAttendeeBySource(ctx, calendarSourcePayment, p.TermID, p.StudentID, calendarRoleAttendee)
	}
	return nil
}

// handlePartnershipMeetingScheduled creates a partner_meeting event with attendees.
func (s *Service) handlePartnershipMeetingScheduled_Calendar(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.PartnershipMeetingScheduledPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	var loc *string
	if p.Location != "" {
		l := p.Location
		loc = &l
	}
	var desc *string
	if p.Agenda != "" {
		d := p.Agenda
		desc = &d
	}
	_, err := s.CreateAutoEvent(ctx, CreateAutoEventInput{
		Title:        p.Title,
		Description:  desc,
		EventType:    CalendarTypePartnerMeeting,
		StartAt:      p.StartAt,
		EndAt:        p.EndAt,
		Location:     loc,
		SourceDomain: calendarSourcePartnershipMeeting,
		SourceID:     p.MeetingID,
	})
	if err != nil {
		s.logCalendarHandlerErr(evt.Type, err)
		return nil
	}
	for _, uid := range p.AttendeeIDs {
		if err := s.AddAttendeeBySource(ctx, calendarSourcePartnershipMeeting, p.MeetingID, uid, calendarRoleAttendee); err != nil {
			s.logCalendarHandlerErr(evt.Type, err)
		}
	}
	return nil
}

// handleFacilitatorApproved_Calendar adds the approved facilitator as attendee on every class_session in the batch.
func (s *Service) handleFacilitatorApproved_Calendar(ctx context.Context, evt events.Event) error {
	p, ok := evt.Payload.(events.FacilitatorApprovedPayload)
	if !ok {
		s.logBadPayload(evt.Type)
		return nil
	}
	if p.BatchID == zeroUUID {
		// No batch context — class events not yet known. Skip silently.
		return nil
	}
	err := s.AddAttendeeToBatchClasses(ctx, p.BatchID, p.FacilitatorID, calendarRoleFacilitator)
	s.logCalendarHandlerErr(evt.Type, err)
	return nil
}
