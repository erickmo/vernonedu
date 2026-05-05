package database

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/calendar"
)

type CalendarRepository struct {
	db *sqlx.DB
}

func NewCalendarRepository(db *sqlx.DB) *CalendarRepository {
	return &CalendarRepository{db: db}
}

type calendarEventRecord struct {
	ID             uuid.UUID  `db:"id"`
	Title          string     `db:"title"`
	Description    *string    `db:"description"`
	EventType      string     `db:"event_type"`
	StartAt        time.Time  `db:"start_at"`
	EndAt          time.Time  `db:"end_at"`
	IsAllDay       bool       `db:"is_all_day"`
	RecurrenceRule *string    `db:"recurrence_rule"`
	Location       *string    `db:"location"`
	SourceDomain   *string    `db:"source_domain"`
	SourceID       *uuid.UUID `db:"source_id"`
	CreatedBy      uuid.UUID  `db:"created_by"`
	CreatedAt      time.Time  `db:"created_at"`
}

func (rec *calendarEventRecord) toDomain() *calendar.CalendarEvent {
	return &calendar.CalendarEvent{
		ID:             rec.ID,
		Title:          rec.Title,
		Description:    rec.Description,
		EventType:      calendar.EventType(rec.EventType),
		StartAt:        rec.StartAt,
		EndAt:          rec.EndAt,
		IsAllDay:       rec.IsAllDay,
		RecurrenceRule: rec.RecurrenceRule,
		Location:       rec.Location,
		SourceDomain:   rec.SourceDomain,
		SourceID:       rec.SourceID,
		CreatedBy:      rec.CreatedBy,
		CreatedAt:      rec.CreatedAt,
	}
}

const calendarCols = `id, title, description, event_type, start_at, end_at, is_all_day, recurrence_rule, location, source_domain, source_id, created_by, created_at`

func (r *CalendarRepository) Save(ctx context.Context, e *calendar.CalendarEvent) error {
	query := `
		INSERT INTO calendar_events (id, title, description, event_type, start_at, end_at,
		    is_all_day, recurrence_rule, location, source_domain, source_id, created_by, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
	`
	_, err := r.db.ExecContext(ctx, query,
		e.ID, e.Title, e.Description, string(e.EventType), e.StartAt, e.EndAt,
		e.IsAllDay, e.RecurrenceRule, e.Location, e.SourceDomain, e.SourceID,
		e.CreatedBy, e.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save calendar event: %w", err)
	}
	return nil
}

func (r *CalendarRepository) Update(ctx context.Context, e *calendar.CalendarEvent) error {
	query := `
		UPDATE calendar_events
		SET title=$1, description=$2, event_type=$3, start_at=$4, end_at=$5,
		    is_all_day=$6, recurrence_rule=$7, location=$8
		WHERE id=$9
	`
	_, err := r.db.ExecContext(ctx, query,
		e.Title, e.Description, string(e.EventType), e.StartAt, e.EndAt,
		e.IsAllDay, e.RecurrenceRule, e.Location, e.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update calendar event: %w", err)
	}
	return nil
}

func (r *CalendarRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM calendar_events WHERE id=$1`, id)
	if err != nil {
		return fmt.Errorf("failed to delete calendar event: %w", err)
	}
	return nil
}

func (r *CalendarRepository) ListByMonth(ctx context.Context, year, month int) ([]*calendar.CalendarEvent, error) {
	firstDay := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.UTC)
	lastDay := firstDay.AddDate(0, 1, 0).Add(-time.Nanosecond)

	var recs []calendarEventRecord
	query := `SELECT ` + calendarCols + ` FROM calendar_events WHERE start_at BETWEEN $1 AND $2 ORDER BY start_at ASC`
	if err := r.db.SelectContext(ctx, &recs, query, firstDay, lastDay); err != nil {
		return nil, fmt.Errorf("failed to list calendar events: %w", err)
	}

	events := make([]*calendar.CalendarEvent, len(recs))
	for i, rec := range recs {
		events[i] = rec.toDomain()
	}
	return events, nil
}

func (r *CalendarRepository) GetByID(ctx context.Context, id uuid.UUID) (*calendar.CalendarEvent, error) {
	var rec calendarEventRecord
	query := `SELECT ` + calendarCols + ` FROM calendar_events WHERE id=$1`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		return nil, fmt.Errorf("failed to get calendar event: %w", err)
	}
	return rec.toDomain(), nil
}
