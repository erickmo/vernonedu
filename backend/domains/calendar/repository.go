package calendar

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

type Repository interface {
	CreateEvent(ctx context.Context, e *CalendarEvent) error
	GetEventByID(ctx context.Context, id uuid.UUID) (*CalendarEvent, error)
	GetEventBySourceID(ctx context.Context, domain SourceDomain, sourceID uuid.UUID) (*CalendarEvent, error)
	UpdateEvent(ctx context.Context, e *CalendarEvent) error
	DeleteEventByID(ctx context.Context, id uuid.UUID) error
	DeleteEventBySourceID(ctx context.Context, domain SourceDomain, sourceID uuid.UUID) error
	ListEvents(ctx context.Context, f ListFilter) ([]*CalendarEvent, error)

	AddAttendee(ctx context.Context, a *CalendarAttendee) error
	AttendeeExists(ctx context.Context, eventID, userID uuid.UUID) (bool, error)
	ListAttendeesByEventID(ctx context.Context, eventID uuid.UUID) ([]*CalendarAttendee, error)
	DeleteAttendeesByEventID(ctx context.Context, eventID uuid.UUID) error
	UpdateRSVP(ctx context.Context, eventID, userID uuid.UUID, status RSVPStatus) error

	UpsertSync(ctx context.Context, s *CalendarSync) error
	GetSyncByUserID(ctx context.Context, userID uuid.UUID) (*CalendarSync, error)

	ListUpcomingClassSessions(ctx context.Context, from, to time.Time) ([]*CalendarEvent, error)
	MarkReminderSent(ctx context.Context, eventID uuid.UUID) error

	GetClassesByBatchID(ctx context.Context, batchID uuid.UUID) ([]*ClassInfo, error)
	GetClassesByCourseID(ctx context.Context, courseID uuid.UUID) ([]*ClassInfo, error)
	GetUserIDByTeamMemberID(ctx context.Context, teamMemberID uuid.UUID) (uuid.UUID, error)
}

type repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) CreateEvent(ctx context.Context, e *CalendarEvent) error {
	e.ID = uuid.New()
	q := `INSERT INTO calendar.events
		(id, title, description, event_type, start_at, end_at, is_all_day,
		 recurrence_rule, location, source_domain, source_id,
		 partnership_agreement_id, agenda, meeting_notes, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
		RETURNING created_at`
	err := r.pool.QueryRow(ctx, q,
		e.ID, e.Title, e.Description, e.EventType, e.StartAt, e.EndAt, e.IsAllDay,
		e.RecurrenceRule, e.Location, e.SourceDomain, e.SourceID,
		e.PartnershipAgreementID, e.Agenda, e.MeetingNotes, e.CreatedBy,
	).Scan(&e.CreatedAt)
	if err != nil {
		return fmt.Errorf("calendar.CreateEvent: %w", err)
	}
	return nil
}

func (r *repository) GetEventByID(ctx context.Context, id uuid.UUID) (*CalendarEvent, error) {
	q := `SELECT id, title, description, event_type, start_at, end_at, is_all_day,
		recurrence_rule, location, source_domain, source_id,
		partnership_agreement_id, agenda, meeting_notes, class_reminder_sent, created_by, created_at
		FROM calendar.events WHERE id = $1`
	row := r.pool.QueryRow(ctx, q, id)
	e, err := scanEvent(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("calendar.GetEventByID: %w", err)
	}
	return e, nil
}

func (r *repository) GetEventBySourceID(ctx context.Context, domain SourceDomain, sourceID uuid.UUID) (*CalendarEvent, error) {
	q := `SELECT id, title, description, event_type, start_at, end_at, is_all_day,
		recurrence_rule, location, source_domain, source_id,
		partnership_agreement_id, agenda, meeting_notes, class_reminder_sent, created_by, created_at
		FROM calendar.events WHERE source_domain = $1 AND source_id = $2 LIMIT 1`
	row := r.pool.QueryRow(ctx, q, domain, sourceID)
	e, err := scanEvent(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("calendar.GetEventBySourceID: %w", err)
	}
	return e, nil
}

func (r *repository) UpdateEvent(ctx context.Context, e *CalendarEvent) error {
	q := `UPDATE calendar.events SET
		title=$2, description=$3, start_at=$4, end_at=$5, is_all_day=$6,
		recurrence_rule=$7, location=$8, agenda=$9, meeting_notes=$10
		WHERE id=$1`
	_, err := r.pool.Exec(ctx, q,
		e.ID, e.Title, e.Description, e.StartAt, e.EndAt, e.IsAllDay,
		e.RecurrenceRule, e.Location, e.Agenda, e.MeetingNotes,
	)
	return err
}

func (r *repository) DeleteEventByID(ctx context.Context, id uuid.UUID) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM calendar.events WHERE id=$1`, id)
	return err
}

func (r *repository) DeleteEventBySourceID(ctx context.Context, domain SourceDomain, sourceID uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`DELETE FROM calendar.events WHERE source_domain=$1 AND source_id=$2`,
		domain, sourceID,
	)
	return err
}

func (r *repository) ListEvents(ctx context.Context, f ListFilter) ([]*CalendarEvent, error) {
	q := `SELECT DISTINCT e.id, e.title, e.description, e.event_type, e.start_at, e.end_at,
		e.is_all_day, e.recurrence_rule, e.location, e.source_domain, e.source_id,
		e.partnership_agreement_id, e.agenda, e.meeting_notes, e.class_reminder_sent,
		e.created_by, e.created_at
		FROM calendar.events e
		LEFT JOIN calendar.attendees a ON a.event_id = e.id
		WHERE ($1::uuid IS NULL OR e.created_by = $1 OR a.user_id = $1)
		  AND ($2::timestamptz IS NULL OR e.start_at >= $2)
		  AND ($3::timestamptz IS NULL OR e.end_at <= $3)
		  AND ($4::text IS NULL OR e.event_type = $4::calendar.event_type)
		ORDER BY e.start_at`
	rows, err := r.pool.Query(ctx, q, f.UserID, f.From, f.To, f.EventType)
	if err != nil {
		return nil, fmt.Errorf("calendar.ListEvents: %w", err)
	}
	defer rows.Close()
	return collectEvents(rows)
}

func (r *repository) AddAttendee(ctx context.Context, a *CalendarAttendee) error {
	a.ID = uuid.New()
	_, err := r.pool.Exec(ctx,
		`INSERT INTO calendar.attendees (id, event_id, user_id, role, rsvp_status)
		 VALUES ($1,$2,$3,$4,$5) ON CONFLICT (event_id, user_id) DO NOTHING`,
		a.ID, a.EventID, a.UserID, a.Role, a.RSVPStatus,
	)
	return err
}

func (r *repository) AttendeeExists(ctx context.Context, eventID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.pool.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM calendar.attendees WHERE event_id=$1 AND user_id=$2)`,
		eventID, userID,
	).Scan(&exists)
	return exists, err
}

func (r *repository) ListAttendeesByEventID(ctx context.Context, eventID uuid.UUID) ([]*CalendarAttendee, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, event_id, user_id, role, rsvp_status FROM calendar.attendees WHERE event_id=$1`,
		eventID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*CalendarAttendee
	for rows.Next() {
		a := &CalendarAttendee{}
		if err := rows.Scan(&a.ID, &a.EventID, &a.UserID, &a.Role, &a.RSVPStatus); err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

func (r *repository) DeleteAttendeesByEventID(ctx context.Context, eventID uuid.UUID) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM calendar.attendees WHERE event_id=$1`, eventID)
	return err
}

func (r *repository) UpdateRSVP(ctx context.Context, eventID, userID uuid.UUID, status RSVPStatus) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE calendar.attendees SET rsvp_status=$3 WHERE event_id=$1 AND user_id=$2`,
		eventID, userID, status,
	)
	return err
}

func (r *repository) UpsertSync(ctx context.Context, s *CalendarSync) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	_, err := r.pool.Exec(ctx,
		`INSERT INTO calendar.syncs (id, user_id, provider, access_token, refresh_token, token_expires_at)
		 VALUES ($1,$2,$3,$4,$5,$6)
		 ON CONFLICT (user_id) DO UPDATE SET
		   access_token=EXCLUDED.access_token,
		   refresh_token=EXCLUDED.refresh_token,
		   token_expires_at=EXCLUDED.token_expires_at`,
		s.ID, s.UserID, s.Provider, s.AccessToken, s.RefreshToken, s.TokenExpiresAt,
	)
	return err
}

func (r *repository) GetSyncByUserID(ctx context.Context, userID uuid.UUID) (*CalendarSync, error) {
	s := &CalendarSync{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, provider, access_token, refresh_token, last_synced_at, token_expires_at
		 FROM calendar.syncs WHERE user_id=$1`,
		userID,
	).Scan(&s.ID, &s.UserID, &s.Provider, &s.AccessToken, &s.RefreshToken,
		&s.LastSyncedAt, &s.TokenExpiresAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, err
	}
	return s, nil
}

func (r *repository) ListUpcomingClassSessions(ctx context.Context, from, to time.Time) ([]*CalendarEvent, error) {
	q := `SELECT id, title, description, event_type, start_at, end_at, is_all_day,
		recurrence_rule, location, source_domain, source_id,
		partnership_agreement_id, agenda, meeting_notes, class_reminder_sent, created_by, created_at
		FROM calendar.events
		WHERE event_type = 'class_session' AND class_reminder_sent = FALSE
		  AND start_at >= $1 AND start_at <= $2
		ORDER BY start_at`
	rows, err := r.pool.Query(ctx, q, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return collectEvents(rows)
}

func (r *repository) MarkReminderSent(ctx context.Context, eventID uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE calendar.events SET class_reminder_sent=TRUE WHERE id=$1`,
		eventID,
	)
	return err
}

func (r *repository) GetClassesByBatchID(ctx context.Context, batchID uuid.UUID) ([]*ClassInfo, error) {
	q := `SELECT id, course_batch_id, title, session_date, start_time, end_time, mode::text, location, online_link
		FROM catalog.classes WHERE course_batch_id=$1 ORDER BY session_date, start_time`
	rows, err := r.pool.Query(ctx, q, batchID)
	if err != nil {
		return nil, fmt.Errorf("calendar.GetClassesByBatchID: %w", err)
	}
	defer rows.Close()
	return collectClasses(rows)
}

func (r *repository) GetClassesByCourseID(ctx context.Context, courseID uuid.UUID) ([]*ClassInfo, error) {
	q := `SELECT c.id, c.course_batch_id, c.title, c.session_date, c.start_time, c.end_time, c.mode::text, c.location, c.online_link
		FROM catalog.classes c
		JOIN catalog.course_batches cb ON c.course_batch_id = cb.id
		WHERE cb.course_id=$1 ORDER BY c.session_date, c.start_time`
	rows, err := r.pool.Query(ctx, q, courseID)
	if err != nil {
		return nil, fmt.Errorf("calendar.GetClassesByCourseID: %w", err)
	}
	defer rows.Close()
	return collectClasses(rows)
}

func (r *repository) GetUserIDByTeamMemberID(ctx context.Context, teamMemberID uuid.UUID) (uuid.UUID, error) {
	var userID uuid.UUID
	err := r.pool.QueryRow(ctx,
		`SELECT user_id FROM team_member.team_members WHERE id=$1`,
		teamMemberID,
	).Scan(&userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return uuid.Nil, apperrors.ErrNotFound
		}
		return uuid.Nil, err
	}
	return userID, nil
}

func scanEvent(row pgx.Row) (*CalendarEvent, error) {
	e := &CalendarEvent{}
	return e, row.Scan(
		&e.ID, &e.Title, &e.Description, &e.EventType, &e.StartAt, &e.EndAt,
		&e.IsAllDay, &e.RecurrenceRule, &e.Location, &e.SourceDomain, &e.SourceID,
		&e.PartnershipAgreementID, &e.Agenda, &e.MeetingNotes, &e.ClassReminderSent,
		&e.CreatedBy, &e.CreatedAt,
	)
}

func collectEvents(rows pgx.Rows) ([]*CalendarEvent, error) {
	var out []*CalendarEvent
	for rows.Next() {
		e := &CalendarEvent{}
		err := rows.Scan(
			&e.ID, &e.Title, &e.Description, &e.EventType, &e.StartAt, &e.EndAt,
			&e.IsAllDay, &e.RecurrenceRule, &e.Location, &e.SourceDomain, &e.SourceID,
			&e.PartnershipAgreementID, &e.Agenda, &e.MeetingNotes, &e.ClassReminderSent,
			&e.CreatedBy, &e.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

func collectClasses(rows pgx.Rows) ([]*ClassInfo, error) {
	var out []*ClassInfo
	for rows.Next() {
		c := &ClassInfo{}
		if err := rows.Scan(&c.ID, &c.BatchID, &c.Title, &c.SessionDate,
			&c.StartTime, &c.EndTime, &c.Mode, &c.Location, &c.OnlineLink); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}
