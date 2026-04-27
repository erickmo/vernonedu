package calendar

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

func (s *Service) CreateEvent(ctx context.Context, e *CalendarEvent) error {
	if e.EndAt.Before(e.StartAt) {
		return apperrors.Validationf("end_at must be after start_at")
	}
	e.SourceDomain = ptr(SourceManual)
	return s.repo.CreateEvent(ctx, e)
}

func (s *Service) GetEvent(ctx context.Context, id uuid.UUID) (*CalendarEvent, error) {
	return s.repo.GetEventByID(ctx, id)
}

func (s *Service) ListEvents(ctx context.Context, f ListFilter) ([]*CalendarEvent, error) {
	return s.repo.ListEvents(ctx, f)
}

func (s *Service) UpdateEvent(ctx context.Context, e *CalendarEvent) error {
	existing, err := s.repo.GetEventByID(ctx, e.ID)
	if err != nil {
		return err
	}
	if existing.SourceDomain != nil && *existing.SourceDomain != SourceManual {
		return apperrors.ErrForbidden
	}
	if e.EndAt.Before(e.StartAt) {
		return apperrors.Validationf("end_at must be after start_at")
	}
	return s.repo.UpdateEvent(ctx, e)
}

func (s *Service) DeleteEvent(ctx context.Context, id uuid.UUID) error {
	existing, err := s.repo.GetEventByID(ctx, id)
	if err != nil {
		return err
	}
	if existing.SourceDomain != nil && *existing.SourceDomain != SourceManual {
		return apperrors.ErrForbidden
	}
	return s.repo.DeleteEventBySourceID(ctx, SourceManual, id)
}

func (s *Service) AddAttendee(ctx context.Context, eventID, userID uuid.UUID, role AttendeeRole) error {
	if _, err := s.repo.GetEventByID(ctx, eventID); err != nil {
		return err
	}
	a := &CalendarAttendee{
		EventID:    eventID,
		UserID:     userID,
		Role:       role,
		RSVPStatus: RSVPPending,
	}
	return s.repo.AddAttendee(ctx, a)
}

func (s *Service) UpdateRSVP(ctx context.Context, eventID, userID uuid.UUID, status RSVPStatus) error {
	return s.repo.UpdateRSVP(ctx, eventID, userID, status)
}

func (s *Service) GetAttendees(ctx context.Context, eventID uuid.UUID) ([]*CalendarAttendee, error) {
	return s.repo.ListAttendeesByEventID(ctx, eventID)
}

func (s *Service) UpsertSync(ctx context.Context, sync *CalendarSync) error {
	return s.repo.UpsertSync(ctx, sync)
}

func (s *Service) GetSync(ctx context.Context, userID uuid.UUID) (*CalendarSync, error) {
	return s.repo.GetSyncByUserID(ctx, userID)
}

func (s *Service) ExportICalForUser(ctx context.Context, userID uuid.UUID) (string, error) {
	evts, err := s.repo.ListEvents(ctx, ListFilter{UserID: &userID})
	if err != nil {
		return "", err
	}
	return buildICal(evts), nil
}

func (s *Service) ExportICalForEvent(ctx context.Context, eventID uuid.UUID) (string, error) {
	e, err := s.repo.GetEventByID(ctx, eventID)
	if err != nil {
		return "", err
	}
	return buildICal([]*CalendarEvent{e}), nil
}

// HandleBatchCreated creates class_session CalendarEvents for each class in the batch.
func (s *Service) HandleBatchCreated(ctx context.Context, batchID, _ uuid.UUID) error {
	classes, err := s.repo.GetClassesByBatchID(ctx, batchID)
	if err != nil {
		return fmt.Errorf("HandleBatchCreated fetch classes: %w", err)
	}
	systemUser := uuid.MustParse("00000000-0000-0000-0000-000000000001")
	for _, c := range classes {
		if err := s.repo.CreateEvent(ctx, classToEvent(c, systemUser)); err != nil {
			s.log.Error("create class_session event failed", zap.String("class_id", c.ID.String()), zap.Error(err))
		}
	}
	return nil
}

// HandleClassRescheduled updates existing class_session event.
func (s *Service) HandleClassRescheduled(ctx context.Context, classID uuid.UUID) error {
	classes, err := s.repo.GetClassesByBatchID(ctx, classID)
	if err != nil || len(classes) == 0 {
		return nil
	}
	existing, err := s.repo.GetEventBySourceID(ctx, SourceCourse, classID)
	if err != nil {
		return nil
	}
	existing.StartAt = combineDateTime(classes[0].SessionDate, classes[0].StartTime)
	existing.EndAt = combineDateTime(classes[0].SessionDate, classes[0].EndTime)
	return s.repo.UpdateEvent(ctx, existing)
}

// HandleClassCancelled removes class_session event and attendees.
func (s *Service) HandleClassCancelled(ctx context.Context, classID uuid.UUID) error {
	return s.repo.DeleteEventBySourceID(ctx, SourceCourse, classID)
}

// HandleFacilitatorAssigned adds facilitator as attendee on class_session event.
func (s *Service) HandleFacilitatorAssigned(ctx context.Context, classID, facilitatorUserID uuid.UUID) error {
	evt, err := s.repo.GetEventBySourceID(ctx, SourceCourse, classID)
	if err != nil {
		return nil
	}
	a := &CalendarAttendee{EventID: evt.ID, UserID: facilitatorUserID, Role: RoleAttendee, RSVPStatus: RSVPPending}
	return s.repo.AddAttendee(ctx, a)
}

// HandleFacilitatorApproved adds facilitator as attendee on all class_session events for course.
func (s *Service) HandleFacilitatorApproved(ctx context.Context, courseID, teamMemberID uuid.UUID) error {
	userID, err := s.repo.GetUserIDByTeamMemberID(ctx, teamMemberID)
	if err != nil {
		return nil
	}
	classes, err := s.repo.GetClassesByCourseID(ctx, courseID)
	if err != nil {
		return nil
	}
	for _, c := range classes {
		evt, err := s.repo.GetEventBySourceID(ctx, SourceCourse, c.ID)
		if err != nil {
			continue
		}
		a := &CalendarAttendee{EventID: evt.ID, UserID: userID, Role: RoleAttendee, RSVPStatus: RSVPPending}
		if err := s.repo.AddAttendee(ctx, a); err != nil {
			s.log.Error("add facilitator attendee failed", zap.Error(err))
		}
	}
	return nil
}

// HandlePaymentTermDue creates a payment_due CalendarEvent.
func (s *Service) HandlePaymentTermDue(ctx context.Context, termID uuid.UUID, dueDate time.Time, createdBy uuid.UUID) error {
	sd := SourcePayment
	title := "Payment Term Due"
	e := &CalendarEvent{
		Title:     title,
		EventType: EventTypePaymentDue,
		StartAt:   dueDate,
		EndAt:     dueDate.Add(1 * time.Hour),
		IsAllDay:  true,
		SourceDomain: &sd,
		SourceID:  &termID,
		CreatedBy: createdBy,
	}
	return s.repo.CreateEvent(ctx, e)
}

// SendUpcomingReminders fires class.reminder for class sessions starting within [from, to].
func (s *Service) SendUpcomingReminders(ctx context.Context, from, to time.Time) error {
	evts, err := s.repo.ListUpcomingClassSessions(ctx, from, to)
	if err != nil {
		return err
	}
	for _, e := range evts {
		if err := s.sendReminder(ctx, e); err != nil {
			s.log.Error("send reminder failed", zap.String("event_id", e.ID.String()), zap.Error(err))
		}
	}
	return nil
}

func (s *Service) sendReminder(ctx context.Context, e *CalendarEvent) error {
	attendees, err := s.repo.ListAttendeesByEventID(ctx, e.ID)
	if err != nil {
		return err
	}
	ids := make([]uuid.UUID, len(attendees))
	for i, a := range attendees {
		ids[i] = a.UserID
	}
	classID := uuid.Nil
	if e.SourceID != nil {
		classID = *e.SourceID
	}
	payload := map[string]any{
		"event_id":     e.ID,
		"class_id":     classID,
		"start_at":     e.StartAt,
		"attendee_ids": ids,
	}
	if err := s.bus.Publish(ctx, events.Event{Type: events.ClassReminder, Payload: payload}); err != nil {
		s.log.Error("publish class.reminder failed", zap.Error(err))
	}
	return s.repo.MarkReminderSent(ctx, e.ID)
}

func classToEvent(c *ClassInfo, createdBy uuid.UUID) *CalendarEvent {
	sd := SourceCourse
	loc := resolveLocation(c)
	title := fmt.Sprintf("Class Session — %s", c.SessionDate.Format("2006-01-02"))
	if c.Title != nil {
		title = *c.Title
	}
	return &CalendarEvent{
		Title:        title,
		EventType:    EventTypeClassSession,
		StartAt:      combineDateTime(c.SessionDate, c.StartTime),
		EndAt:        combineDateTime(c.SessionDate, c.EndTime),
		IsAllDay:     false,
		Location:     loc,
		SourceDomain: &sd,
		SourceID:     &c.ID,
		CreatedBy:    createdBy,
	}
}

func combineDateTime(date, t time.Time) time.Time {
	return time.Date(date.Year(), date.Month(), date.Day(),
		t.Hour(), t.Minute(), t.Second(), 0, time.UTC)
}

func resolveLocation(c *ClassInfo) *string {
	if c.Mode == "online" && c.OnlineLink != nil {
		return c.OnlineLink
	}
	return c.Location
}

func buildICal(evts []*CalendarEvent) string {
	var sb strings.Builder
	sb.WriteString("BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//VernonEdu//Calendar//EN\r\nCALSCALE:GREGORIAN\r\n")
	for _, e := range evts {
		sb.WriteString(buildICalEvent(e))
	}
	sb.WriteString("END:VCALENDAR\r\n")
	return sb.String()
}

func buildICalEvent(e *CalendarEvent) string {
	var sb strings.Builder
	sb.WriteString("BEGIN:VEVENT\r\n")
	sb.WriteString(fmt.Sprintf("UID:%s@vernonedu\r\n", e.ID))
	sb.WriteString(fmt.Sprintf("DTSTART:%s\r\n", e.StartAt.UTC().Format("20060102T150405Z")))
	sb.WriteString(fmt.Sprintf("DTEND:%s\r\n", e.EndAt.UTC().Format("20060102T150405Z")))
	sb.WriteString(fmt.Sprintf("SUMMARY:%s\r\n", escapeICal(e.Title)))
	if e.Description != nil {
		sb.WriteString(fmt.Sprintf("DESCRIPTION:%s\r\n", escapeICal(*e.Description)))
	}
	if e.Location != nil {
		sb.WriteString(fmt.Sprintf("LOCATION:%s\r\n", escapeICal(*e.Location)))
	}
	if e.RecurrenceRule != nil {
		sb.WriteString(fmt.Sprintf("RRULE:%s\r\n", *e.RecurrenceRule))
	}
	sb.WriteString("END:VEVENT\r\n")
	return sb.String()
}

func escapeICal(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, ";", "\\;")
	s = strings.ReplaceAll(s, ",", "\\,")
	s = strings.ReplaceAll(s, "\n", "\\n")
	return s
}

func ptr[T any](v T) *T { return &v }
