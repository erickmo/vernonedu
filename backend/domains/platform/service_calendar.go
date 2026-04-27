package platform

import (
	"context"
	"time"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// CreateManualEventInput captures the parameters for manually scheduled events.
type CreateManualEventInput struct {
	Title       string
	Description *string
	StartAt     time.Time
	EndAt       time.Time
	Location    *string
	Rrule       *string
	CreatorID   uuid.UUID
	Internal    bool
}

// CreateManualEvent stores an event of type manual_internal or manual_personal.
func (s *Service) CreateManualEvent(ctx context.Context, in CreateManualEventInput) (*CalendarEvent, error) {
	if in.Title == "" {
		return nil, apperrors.Validationf("title is required")
	}
	if !in.EndAt.After(in.StartAt) {
		return nil, apperrors.Validationf("end_at must be after start_at")
	}

	eventType := CalendarTypeManualPersonal
	if in.Internal {
		eventType = CalendarTypeManualInternal
	}

	creator := in.CreatorID
	evt := &CalendarEvent{
		ID:          uuid.New(),
		Title:       in.Title,
		Description: in.Description,
		EventType:   eventType,
		StartAt:     in.StartAt,
		EndAt:       in.EndAt,
		Location:    in.Location,
		Rrule:       in.Rrule,
		CreatedBy:   &creator,
	}
	if err := s.repo.CreateCalendarEvent(ctx, evt); err != nil {
		return nil, err
	}
	return evt, nil
}

// AddAttendee invites a user to an event.
// Returns apperrors.ErrConflict on duplicate (event_id, user_id).
func (s *Service) AddAttendee(ctx context.Context, eventID, userID uuid.UUID, role string) (*CalendarAttendee, error) {
	a := &CalendarAttendee{
		ID:         uuid.New(),
		EventID:    eventID,
		UserID:     userID,
		Role:       role,
		RsvpStatus: RsvpPending,
	}
	if err := s.repo.AddCalendarAttendee(ctx, a); err != nil {
		return nil, err
	}
	return a, nil
}

// ListEventsByUser returns events where the user is creator or attendee.
func (s *Service) ListEventsByUser(ctx context.Context, userID uuid.UUID) ([]*CalendarEvent, error) {
	return s.repo.ListCalendarEventsByUser(ctx, userID)
}

// UpdateEvent updates a manual event. Auto-created events (source_id != nil)
// cannot be edited via the manual API.
func (s *Service) UpdateEvent(ctx context.Context, evt *CalendarEvent) error {
	existing, err := s.repo.GetCalendarEvent(ctx, evt.ID)
	if err != nil {
		return err
	}
	if existing.SourceID != nil {
		return apperrors.ErrAutoCreatedReadOnly
	}
	return s.repo.UpdateCalendarEvent(ctx, evt)
}

// DeleteEvent removes an event; attendees cascade via FK ON DELETE CASCADE.
func (s *Service) DeleteEvent(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteCalendarEvent(ctx, id)
}
