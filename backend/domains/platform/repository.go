package platform

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// pgUniqueViolation is the SQLSTATE code for unique constraint violations.
const pgUniqueViolation = "23505"

// Repository defines platform data access.
type Repository interface {
	CreateTemplate(ctx context.Context, t *NotificationTemplate) error
	GetTemplateByID(ctx context.Context, id uuid.UUID) (*NotificationTemplate, error)
	GetTemplateByKey(ctx context.Context, key string, channel NotificationChannel) (*NotificationTemplate, error)
	DeactivateTemplate(ctx context.Context, id uuid.UUID) error
	CreateNotification(ctx context.Context, n *Notification) error
	GetNotificationByID(ctx context.Context, id uuid.UUID) (*Notification, error)
	UpdateNotificationStatus(ctx context.Context, id uuid.UUID, status NotificationStatus) error
	MarkNotificationSent(ctx context.Context, id uuid.UUID) error
	RecordNotificationFailure(ctx context.Context, id uuid.UUID, errMsg string) error
	ListPendingNotifications(ctx context.Context, limit int) ([]*Notification, error)
	ListNotificationsByRecipient(ctx context.Context, recipientID uuid.UUID, limit, offset int) ([]*Notification, error)
	MarkNotificationRead(ctx context.Context, id uuid.UUID) error

	GetPreference(ctx context.Context, userID uuid.UUID, templateKey string, channel NotificationChannel) (*NotificationPreference, error)
	UpsertPreference(ctx context.Context, pref *NotificationPreference) error

	// Calendar
	CreateCalendarEvent(ctx context.Context, e *CalendarEvent) error
	GetCalendarEvent(ctx context.Context, id uuid.UUID) (*CalendarEvent, error)
	UpdateCalendarEvent(ctx context.Context, e *CalendarEvent) error
	DeleteCalendarEvent(ctx context.Context, id uuid.UUID) error
	ListCalendarEventsByUser(ctx context.Context, userID uuid.UUID) ([]*CalendarEvent, error)
	AddCalendarAttendee(ctx context.Context, a *CalendarAttendee) error
	RemoveCalendarAttendee(ctx context.Context, eventID, userID uuid.UUID) error
	ListCalendarAttendeesByEvent(ctx context.Context, eventID uuid.UUID) ([]*CalendarAttendee, error)
}

type repository struct {
	pool *pgxpool.Pool
}

// NewRepository creates platform repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &repository{pool: pool}
}

func (r *repository) CreateTemplate(ctx context.Context, t *NotificationTemplate) error {
	query := `
		INSERT INTO platform.notification_templates (id, key, channel, subject, body, is_active)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		t.ID, t.Key, t.Channel, t.Subject, t.Body, t.IsActive,
	).Scan(&t.CreatedAt, &t.UpdatedAt)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == pgUniqueViolation {
			return apperrors.ErrConflict
		}
		return fmt.Errorf("platform.CreateTemplate: %w", err)
	}
	return nil
}

func (r *repository) GetTemplateByID(ctx context.Context, id uuid.UUID) (*NotificationTemplate, error) {
	query := `SELECT id, key, channel, subject, body, is_active, created_at, updated_at
	          FROM platform.notification_templates WHERE id=$1`

	t := &NotificationTemplate{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&t.ID, &t.Key, &t.Channel, &t.Subject, &t.Body, &t.IsActive, &t.CreatedAt, &t.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("platform.GetTemplateByID: %w", err)
	}
	return t, nil
}

func (r *repository) DeactivateTemplate(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE platform.notification_templates SET is_active=false WHERE id=$1`
	ct, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("platform.DeactivateTemplate: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) GetTemplateByKey(ctx context.Context, key string, channel NotificationChannel) (*NotificationTemplate, error) {
	query := `SELECT id, key, channel, subject, body, is_active, created_at, updated_at
	          FROM platform.notification_templates WHERE key=$1 AND channel=$2 AND is_active=true`

	t := &NotificationTemplate{}
	err := r.pool.QueryRow(ctx, query, key, channel).Scan(
		&t.ID, &t.Key, &t.Channel, &t.Subject, &t.Body, &t.IsActive, &t.CreatedAt, &t.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("platform.GetTemplateByKey: %w", err)
	}
	return t, nil
}

func (r *repository) CreateNotification(ctx context.Context, n *Notification) error {
	query := `
		INSERT INTO platform.notifications
		  (id, recipient_id, template_id, channel, variables, status, source_domain, source_id, scheduled_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		n.ID, n.RecipientID, n.TemplateID, n.Channel, n.Variables,
		n.Status, n.SourceDomain, n.SourceID, n.ScheduledAt,
	).Scan(&n.CreatedAt, &n.UpdatedAt)
	if err != nil {
		return fmt.Errorf("platform.CreateNotification: %w", err)
	}
	return nil
}

func (r *repository) GetNotificationByID(ctx context.Context, id uuid.UUID) (*Notification, error) {
	query := `SELECT id, recipient_id, template_id, channel, variables, status, source_domain, source_id,
	                 scheduled_at, sent_at, read_at, retry_count, error_message, created_at, updated_at
	          FROM platform.notifications WHERE id = $1`

	n := &Notification{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&n.ID, &n.RecipientID, &n.TemplateID, &n.Channel, &n.Variables, &n.Status,
		&n.SourceDomain, &n.SourceID, &n.ScheduledAt, &n.SentAt, &n.ReadAt,
		&n.RetryCount, &n.ErrorMessage, &n.CreatedAt, &n.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("platform.GetNotificationByID: %w", err)
	}
	return n, nil
}

func (r *repository) UpdateNotificationStatus(ctx context.Context, id uuid.UUID, status NotificationStatus) error {
	query := `UPDATE platform.notifications SET status=$1, sent_at = CASE WHEN $1='sent' THEN now() ELSE sent_at END WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("platform.UpdateNotificationStatus: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) MarkNotificationSent(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE platform.notifications
	          SET status='sent', sent_at=now(), error_message=NULL, updated_at=now()
	          WHERE id=$1`
	ct, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("platform.MarkNotificationSent: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) RecordNotificationFailure(ctx context.Context, id uuid.UUID, errMsg string) error {
	query := `UPDATE platform.notifications
	          SET retry_count = retry_count + 1,
	              status = CASE WHEN retry_count + 1 >= $2 THEN 'failed' ELSE status END,
	              error_message = $3,
	              updated_at = now()
	          WHERE id = $1`
	ct, err := r.pool.Exec(ctx, query, id, MaxNotificationRetries, errMsg)
	if err != nil {
		return fmt.Errorf("platform.RecordNotificationFailure: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *repository) ListPendingNotifications(ctx context.Context, limit int) ([]*Notification, error) {
	query := `SELECT id, recipient_id, template_id, channel, variables, status, source_domain, source_id,
	                 scheduled_at, sent_at, read_at, retry_count, error_message, created_at, updated_at
	          FROM platform.notifications WHERE status='pending' AND (scheduled_at IS NULL OR scheduled_at <= now())
	          ORDER BY created_at LIMIT $1`

	rows, err := r.pool.Query(ctx, query, limit)
	if err != nil {
		return nil, fmt.Errorf("platform.ListPendingNotifications: %w", err)
	}
	defer rows.Close()

	var notifs []*Notification
	for rows.Next() {
		n := &Notification{}
		if err := rows.Scan(
			&n.ID, &n.RecipientID, &n.TemplateID, &n.Channel, &n.Variables, &n.Status,
			&n.SourceDomain, &n.SourceID, &n.ScheduledAt, &n.SentAt, &n.ReadAt,
			&n.RetryCount, &n.ErrorMessage, &n.CreatedAt, &n.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("platform.ListPendingNotifications scan: %w", err)
		}
		notifs = append(notifs, n)
	}
	return notifs, rows.Err()
}

func (r *repository) ListNotificationsByRecipient(ctx context.Context, recipientID uuid.UUID, limit, offset int) ([]*Notification, error) {
	query := `SELECT id, recipient_id, template_id, channel, variables, status, source_domain, source_id,
	                 scheduled_at, sent_at, read_at, retry_count, error_message, created_at, updated_at
	          FROM platform.notifications WHERE recipient_id=$1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`

	rows, err := r.pool.Query(ctx, query, recipientID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("platform.ListNotificationsByRecipient: %w", err)
	}
	defer rows.Close()

	var notifs []*Notification
	for rows.Next() {
		n := &Notification{}
		if err := rows.Scan(
			&n.ID, &n.RecipientID, &n.TemplateID, &n.Channel, &n.Variables, &n.Status,
			&n.SourceDomain, &n.SourceID, &n.ScheduledAt, &n.SentAt, &n.ReadAt,
			&n.RetryCount, &n.ErrorMessage, &n.CreatedAt, &n.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("platform.ListNotificationsByRecipient scan: %w", err)
		}
		notifs = append(notifs, n)
	}
	return notifs, rows.Err()
}

func (r *repository) MarkNotificationRead(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE platform.notifications SET status='read', read_at=now() WHERE id=$1 AND status='sent'`
	_, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("platform.MarkNotificationRead: %w", err)
	}
	return nil
}

func (r *repository) GetPreference(ctx context.Context, userID uuid.UUID, templateKey string, channel NotificationChannel) (*NotificationPreference, error) {
	query := `SELECT id, user_id, template_key, channel, enabled, created_at, updated_at
	          FROM platform.notification_preferences WHERE user_id=$1 AND template_key=$2 AND channel=$3`

	pref := &NotificationPreference{}
	err := r.pool.QueryRow(ctx, query, userID, templateKey, channel).Scan(
		&pref.ID, &pref.UserID, &pref.TemplateKey, &pref.Channel, &pref.Enabled, &pref.CreatedAt, &pref.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("platform.GetPreference: %w", err)
	}
	return pref, nil
}

func (r *repository) UpsertPreference(ctx context.Context, pref *NotificationPreference) error {
	query := `
		INSERT INTO platform.notification_preferences (id, user_id, template_key, channel, enabled)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (user_id, template_key, channel) DO UPDATE SET enabled=EXCLUDED.enabled
		RETURNING created_at, updated_at`

	err := r.pool.QueryRow(ctx, query, pref.ID, pref.UserID, pref.TemplateKey, pref.Channel, pref.Enabled).
		Scan(&pref.CreatedAt, &pref.UpdatedAt)
	if err != nil {
		return fmt.Errorf("platform.UpsertPreference: %w", err)
	}
	return nil
}
