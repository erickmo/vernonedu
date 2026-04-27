package platform

import (
	"context"
	"errors"
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

// CreateAutoEventInput captures the parameters for cross-domain auto-created events.
type CreateAutoEventInput struct {
	Title        string
	Description  *string
	EventType    CalendarEventType
	StartAt      time.Time
	EndAt        time.Time
	Location     *string
	SourceDomain string
	SourceID     uuid.UUID
	BatchID      *uuid.UUID
}

// CreateAutoEvent stores a calendar event tagged with source_domain/source_id so
// the originating domain can later locate and update or delete it.
func (s *Service) CreateAutoEvent(ctx context.Context, in CreateAutoEventInput) (*CalendarEvent, error) {
	if in.Title == "" {
		return nil, apperrors.Validationf("title is required")
	}
	if !in.EndAt.After(in.StartAt) {
		return nil, apperrors.Validationf("end_at must be after start_at")
	}
	src := in.SourceDomain
	srcID := in.SourceID
	evt := &CalendarEvent{
		ID:           uuid.New(),
		Title:        in.Title,
		Description:  in.Description,
		EventType:    in.EventType,
		StartAt:      in.StartAt,
		EndAt:        in.EndAt,
		Location:     in.Location,
		SourceDomain: &src,
		SourceID:     &srcID,
		BatchID:      in.BatchID,
	}
	if err := s.repo.CreateCalendarEvent(ctx, evt); err != nil {
		return nil, err
	}
	return evt, nil
}

// FindEventBySource returns the auto-created event for (sourceDomain, sourceID).
// Returns (nil, nil) when missing — callers treat absence as a no-op.
func (s *Service) FindEventBySource(ctx context.Context, sourceDomain string, sourceID uuid.UUID) (*CalendarEvent, error) {
	evt, err := s.repo.GetCalendarEventBySource(ctx, sourceDomain, sourceID)
	if err != nil {
		if errors.Is(err, apperrors.ErrNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return evt, nil
}

// UpdateEventTimes mutates start_at/end_at for the auto-created event keyed by source.
func (s *Service) UpdateEventTimes(ctx context.Context, sourceDomain string, sourceID uuid.UUID, start, end time.Time) error {
	if !end.After(start) {
		return apperrors.Validationf("end_at must be after start_at")
	}
	err := s.repo.UpdateCalendarEventTimes(ctx, sourceDomain, sourceID, start, end)
	if errors.Is(err, apperrors.ErrNotFound) {
		return nil
	}
	return err
}

// DeleteEventBySource removes the auto-created event keyed by source. Missing rows are a no-op.
func (s *Service) DeleteEventBySource(ctx context.Context, sourceDomain string, sourceID uuid.UUID) error {
	return s.repo.DeleteCalendarEventBySource(ctx, sourceDomain, sourceID)
}

// AddAttendeeBySource resolves the event by (sourceDomain, sourceID) and adds an attendee.
// Skips silently when the event is not found or the user is already attending.
func (s *Service) AddAttendeeBySource(ctx context.Context, sourceDomain string, sourceID uuid.UUID, userID uuid.UUID, role string) error {
	evt, err := s.FindEventBySource(ctx, sourceDomain, sourceID)
	if err != nil {
		return err
	}
	if evt == nil {
		return nil
	}
	_, err = s.AddAttendee(ctx, evt.ID, userID, role)
	if errors.Is(err, apperrors.ErrConflict) {
		return nil
	}
	return err
}

// AddAttendeeToBatchClasses adds userID as an attendee to every class_session
// calendar event tagged with batchID. Used when a facilitator gets approved.
func (s *Service) AddAttendeeToBatchClasses(ctx context.Context, batchID uuid.UUID, userID uuid.UUID, role string) error {
	events, err := s.repo.ListCalendarEventsByBatchID(ctx, batchID)
	if err != nil {
		return err
	}
	for _, e := range events {
		if _, err := s.AddAttendee(ctx, e.ID, userID, role); err != nil {
			if errors.Is(err, apperrors.ErrConflict) {
				continue
			}
			return err
		}
	}
	return nil
}
