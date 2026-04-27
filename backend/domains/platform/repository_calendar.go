package platform

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

func (r *repository) CreateCalendarEvent(ctx context.Context, e *CalendarEvent) error {
	query := `
		INSERT INTO platform.calendar_events
		  (id, title, description, event_type, start_at, end_at, location, rrule,
		   source_domain, source_id, batch_id, created_by, reminder_fired_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		e.ID, e.Title, e.Description, e.EventType, e.StartAt, e.EndAt,
		e.Location, e.Rrule, e.SourceDomain, e.SourceID, e.BatchID, e.CreatedBy, e.ReminderFiredAt,
	).Scan(&e.CreatedAt, &e.UpdatedAt)
	if err != nil {
		return fmt.Errorf("platform.CreateCalendarEvent: %w", err)
	}
	return nil
}

func (r *repository) GetCalendarEvent(ctx context.Context, id uuid.UUID) (*CalendarEvent, error) {
	query := `SELECT id, title, description, event_type, start_at, end_at, location, rrule,
	                 source_domain, source_id, batch_id, created_by, reminder_fired_at, created_at, updated_at
	          FROM platform.calendar_events WHERE id=$1`

	e := &CalendarEvent{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&e.ID, &e.Title, &e.Description, &e.EventType, &e.StartAt, &e.EndAt,
		&e.Location, &e.Rrule, &e.SourceDomain, &e.SourceID, &e.BatchID, &e.CreatedBy,
		&e.ReminderFiredAt, &e.CreatedAt, &e.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("platform.GetCalendarEvent: %w", err)
	}
	return e, nil
}

func (r *repository) GetCalendarEventBySource(ctx context.Context, sourceDomain string, sourceID uuid.UUID) (*CalendarEvent, error) {
	query := `SELECT id, title, description, event_type, start_at, end_at, location, rrule,
	                 source_domain, source_id, batch_id, created_by, reminder_fired_at, created_at, updated_at
	          FROM platform.calendar_events WHERE source_domain=$1 AND source_id=$2`

	e := &CalendarEvent{}
	err := r.pool.QueryRow(ctx, query, sourceDomain, sourceID).Scan(
		&e.ID, &e.Title, &e.Description, &e.EventType, &e.StartAt, &e.EndAt,
		&e.Location, &e.Rrule, &e.SourceDomain, &e.SourceID, &e.BatchID, &e.CreatedBy,
		&e.ReminderFiredAt, &e.CreatedAt, &e.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("platform.GetCalendarEventBySource: %w", err)
	}
	return e, nil
}

func (r *repository) UpdateCalendarEvent(ctx context.Context, e *CalendarEvent) error {
	query := `UPDATE platform.calendar_events
	          SET title=$2, description=$3, start_at=$4, end_at=$5, location=$6, rrule=$7,
	              reminder_fired_at=$8, updated_at=now()
	          WHERE id=$1
	          RETURNING updated_at`
	err := r.pool.QueryRow(ctx, query,
		e.ID, e.Title, e.Description, e.StartAt, e.EndAt, e.Location, e.Rrule, e.ReminderFiredAt,
	).Scan(&e.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return apperrors.ErrNotFound
		}
		return fmt.Errorf("platform.UpdateCalendarEvent: %w", err)
	}
	return nil
}

func (r *repository) UpdateCalendarEventTimes(ctx context.Context, sourceDomain string, sourceID uuid.UUID, start, end time.Time) error {
	ct, err := r.pool.Exec(ctx,
		`UPDATE platform.calendar_events
		   SET start_at=$3, end_at=$4, updated_at=now()
		 WHERE source_domain=$1 AND source_id=$2`,
		sourceDomain, sourceID, start, end,
	)
	if err != nil {
		return fmt.Errorf("platform.UpdateCalendarEventTimes: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) DeleteCalendarEvent(ctx context.Context, id uuid.UUID) error {
	ct, err := r.pool.Exec(ctx, `DELETE FROM platform.calendar_events WHERE id=$1`, id)
	if err != nil {
		return fmt.Errorf("platform.DeleteCalendarEvent: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) DeleteCalendarEventBySource(ctx context.Context, sourceDomain string, sourceID uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`DELETE FROM platform.calendar_events WHERE source_domain=$1 AND source_id=$2`,
		sourceDomain, sourceID,
	)
	if err != nil {
		return fmt.Errorf("platform.DeleteCalendarEventBySource: %w", err)
	}
	return nil
}

func (r *repository) ListCalendarEventsByUser(ctx context.Context, userID uuid.UUID) ([]*CalendarEvent, error) {
	query := `SELECT DISTINCT e.id, e.title, e.description, e.event_type, e.start_at, e.end_at,
	                 e.location, e.rrule, e.source_domain, e.source_id, e.batch_id, e.created_by,
	                 e.reminder_fired_at, e.created_at, e.updated_at
	          FROM platform.calendar_events e
	          LEFT JOIN platform.calendar_attendees a ON a.event_id = e.id
	          WHERE e.created_by = $1 OR a.user_id = $1
	          ORDER BY e.start_at`

	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("platform.ListCalendarEventsByUser: %w", err)
	}
	defer rows.Close()

	var events []*CalendarEvent
	for rows.Next() {
		e := &CalendarEvent{}
		if err := rows.Scan(
			&e.ID, &e.Title, &e.Description, &e.EventType, &e.StartAt, &e.EndAt,
			&e.Location, &e.Rrule, &e.SourceDomain, &e.SourceID, &e.BatchID, &e.CreatedBy,
			&e.ReminderFiredAt, &e.CreatedAt, &e.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("platform.ListCalendarEventsByUser scan: %w", err)
		}
		events = append(events, e)
	}
	return events, rows.Err()
}

func (r *repository) ListCalendarEventsByBatchID(ctx context.Context, batchID uuid.UUID) ([]*CalendarEvent, error) {
	query := `SELECT id, title, description, event_type, start_at, end_at, location, rrule,
	                 source_domain, source_id, batch_id, created_by, reminder_fired_at, created_at, updated_at
	          FROM platform.calendar_events
	          WHERE batch_id=$1 AND event_type='class_session'
	          ORDER BY start_at`

	rows, err := r.pool.Query(ctx, query, batchID)
	if err != nil {
		return nil, fmt.Errorf("platform.ListCalendarEventsByBatchID: %w", err)
	}
	defer rows.Close()

	var events []*CalendarEvent
	for rows.Next() {
		e := &CalendarEvent{}
		if err := rows.Scan(
			&e.ID, &e.Title, &e.Description, &e.EventType, &e.StartAt, &e.EndAt,
			&e.Location, &e.Rrule, &e.SourceDomain, &e.SourceID, &e.BatchID, &e.CreatedBy,
			&e.ReminderFiredAt, &e.CreatedAt, &e.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("platform.ListCalendarEventsByBatchID scan: %w", err)
		}
		events = append(events, e)
	}
	return events, rows.Err()
}

func (r *repository) AddCalendarAttendee(ctx context.Context, a *CalendarAttendee) error {
	if a.RsvpStatus == "" {
		a.RsvpStatus = RsvpPending
	}
	query := `
		INSERT INTO platform.calendar_attendees (id, event_id, user_id, role, rsvp_status)
		VALUES ($1,$2,$3,$4,$5)
		RETURNING created_at`
	err := r.pool.QueryRow(ctx, query, a.ID, a.EventID, a.UserID, a.Role, a.RsvpStatus).
		Scan(&a.CreatedAt)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgUniqueViolation {
			return apperrors.ErrConflict
		}
		return fmt.Errorf("platform.AddCalendarAttendee: %w", err)
	}
	return nil
}

func (r *repository) RemoveCalendarAttendee(ctx context.Context, eventID, userID uuid.UUID) error {
	ct, err := r.pool.Exec(ctx,
		`DELETE FROM platform.calendar_attendees WHERE event_id=$1 AND user_id=$2`,
		eventID, userID,
	)
	if err != nil {
		return fmt.Errorf("platform.RemoveCalendarAttendee: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListCalendarAttendeesByEvent(ctx context.Context, eventID uuid.UUID) ([]*CalendarAttendee, error) {
	query := `SELECT id, event_id, user_id, role, rsvp_status, created_at
	          FROM platform.calendar_attendees WHERE event_id=$1 ORDER BY created_at`

	rows, err := r.pool.Query(ctx, query, eventID)
	if err != nil {
		return nil, fmt.Errorf("platform.ListCalendarAttendeesByEvent: %w", err)
	}
	defer rows.Close()

	var out []*CalendarAttendee
	for rows.Next() {
		a := &CalendarAttendee{}
		if err := rows.Scan(&a.ID, &a.EventID, &a.UserID, &a.Role, &a.RsvpStatus, &a.CreatedAt); err != nil {
			return nil, fmt.Errorf("platform.ListCalendarAttendeesByEvent scan: %w", err)
		}
		out = append(out, a)
	}
	return out, rows.Err()
}
