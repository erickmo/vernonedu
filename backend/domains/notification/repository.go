package notification

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// Repository defines all persistence operations for the notification domain.
type Repository interface {
	// Templates
	CreateTemplate(ctx context.Context, t *NotificationTemplate) error
	GetTemplateByID(ctx context.Context, id uuid.UUID) (*NotificationTemplate, error)
	GetTemplateByKeyChannel(ctx context.Context, key string, ch Channel) (*NotificationTemplate, error)
	ListTemplates(ctx context.Context) ([]*NotificationTemplate, error)
	UpdateTemplate(ctx context.Context, t *NotificationTemplate) error
	DeleteTemplate(ctx context.Context, id uuid.UUID) error

	// Notifications
	CreateNotification(ctx context.Context, n *Notification) error
	GetNotificationByID(ctx context.Context, id uuid.UUID) (*Notification, error)
	ListNotifications(ctx context.Context, f ListNotifFilter) ([]*Notification, error)
	UpdateStatus(ctx context.Context, id uuid.UUID, status NotifStatus, sentAt *time.Time, errMsg *string) error
	MarkRead(ctx context.Context, id uuid.UUID, userID uuid.UUID) error
	CountUnread(ctx context.Context, userID uuid.UUID) (int, error)
	ListPending(ctx context.Context, now time.Time, limit int) ([]*Notification, error)
	IncrementRetry(ctx context.Context, id uuid.UUID, errMsg string) error

	// Preferences
	UpsertPreference(ctx context.Context, p *NotificationPreference) error
	GetPreference(ctx context.Context, userID uuid.UUID, key string, ch Channel) (*NotificationPreference, error)
	ListPreferences(ctx context.Context, userID uuid.UUID) ([]*NotificationPreference, error)
}

type pgRepository struct {
	pool *pgxpool.Pool
}

// NewRepository creates a new pgx-backed Repository.
func NewRepository(pool *pgxpool.Pool) Repository {
	return &pgRepository{pool: pool}
}

// ── Templates ─────────────────────────────────────────────────────────────────

func (r *pgRepository) CreateTemplate(ctx context.Context, t *NotificationTemplate) error {
	const q = `
		INSERT INTO notification.templates (key, channel, subject, body, is_active)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at`
	return r.pool.QueryRow(ctx, q, t.Key, t.Channel, t.Subject, t.Body, t.IsActive).
		Scan(&t.ID, &t.CreatedAt, &t.UpdatedAt)
}

func (r *pgRepository) GetTemplateByID(ctx context.Context, id uuid.UUID) (*NotificationTemplate, error) {
	const q = `SELECT id, key, channel, subject, body, is_active, created_at, updated_at
		FROM notification.templates WHERE id = $1`
	t := &NotificationTemplate{}
	err := r.pool.QueryRow(ctx, q, id).Scan(
		&t.ID, &t.Key, &t.Channel, &t.Subject, &t.Body, &t.IsActive, &t.CreatedAt, &t.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, apperrors.ErrNotFound
	}
	return t, err
}

func (r *pgRepository) GetTemplateByKeyChannel(ctx context.Context, key string, ch Channel) (*NotificationTemplate, error) {
	const q = `SELECT id, key, channel, subject, body, is_active, created_at, updated_at
		FROM notification.templates WHERE key = $1 AND channel = $2`
	t := &NotificationTemplate{}
	err := r.pool.QueryRow(ctx, q, key, ch).Scan(
		&t.ID, &t.Key, &t.Channel, &t.Subject, &t.Body, &t.IsActive, &t.CreatedAt, &t.UpdatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, apperrors.ErrNotFound
	}
	return t, err
}

func (r *pgRepository) ListTemplates(ctx context.Context) ([]*NotificationTemplate, error) {
	const q = `SELECT id, key, channel, subject, body, is_active, created_at, updated_at
		FROM notification.templates ORDER BY key, channel`
	rows, err := r.pool.Query(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var templates []*NotificationTemplate
	for rows.Next() {
		t := &NotificationTemplate{}
		if err := rows.Scan(&t.ID, &t.Key, &t.Channel, &t.Subject, &t.Body, &t.IsActive, &t.CreatedAt, &t.UpdatedAt); err != nil {
			return nil, err
		}
		templates = append(templates, t)
	}
	return templates, rows.Err()
}

func (r *pgRepository) UpdateTemplate(ctx context.Context, t *NotificationTemplate) error {
	const q = `UPDATE notification.templates
		SET key=$1, channel=$2, subject=$3, body=$4, is_active=$5, updated_at=now()
		WHERE id=$6
		RETURNING updated_at`
	err := r.pool.QueryRow(ctx, q, t.Key, t.Channel, t.Subject, t.Body, t.IsActive, t.ID).
		Scan(&t.UpdatedAt)
	if err == pgx.ErrNoRows {
		return apperrors.ErrNotFound
	}
	return err
}

func (r *pgRepository) DeleteTemplate(ctx context.Context, id uuid.UUID) error {
	const q = `DELETE FROM notification.templates WHERE id = $1`
	tag, err := r.pool.Exec(ctx, q, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

// ── Notifications ─────────────────────────────────────────────────────────────

func (r *pgRepository) CreateNotification(ctx context.Context, n *Notification) error {
	varsJSON, err := json.Marshal(n.Variables)
	if err != nil {
		return err
	}
	const q = `
		INSERT INTO notification.notifications
			(recipient_id, template_id, channel, variables, status, source_domain, source_id, scheduled_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at`
	return r.pool.QueryRow(ctx, q,
		n.RecipientID, n.TemplateID, n.Channel, varsJSON,
		n.Status, n.SourceDomain, n.SourceID, n.ScheduledAt,
	).Scan(&n.ID, &n.CreatedAt)
}

func (r *pgRepository) GetNotificationByID(ctx context.Context, id uuid.UUID) (*Notification, error) {
	const q = `SELECT id, recipient_id, template_id, channel, variables, status,
		source_domain, source_id, scheduled_at, sent_at, read_at, retry_count, error_message, created_at
		FROM notification.notifications WHERE id = $1`
	n := &Notification{}
	var varsRaw []byte
	err := r.pool.QueryRow(ctx, q, id).Scan(
		&n.ID, &n.RecipientID, &n.TemplateID, &n.Channel, &varsRaw, &n.Status,
		&n.SourceDomain, &n.SourceID, &n.ScheduledAt, &n.SentAt, &n.ReadAt,
		&n.RetryCount, &n.ErrorMessage, &n.CreatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, apperrors.ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return n, json.Unmarshal(varsRaw, &n.Variables)
}

func (r *pgRepository) ListNotifications(ctx context.Context, f ListNotifFilter) ([]*Notification, error) {
	q := `SELECT id, recipient_id, template_id, channel, variables, status,
		source_domain, source_id, scheduled_at, sent_at, read_at, retry_count, error_message, created_at
		FROM notification.notifications WHERE 1=1`
	args := []any{}
	i := 1

	if f.RecipientID != nil {
		q += ` AND recipient_id = $` + itoa(i)
		args = append(args, *f.RecipientID)
		i++
	}
	if f.Status != nil {
		q += ` AND status = $` + itoa(i)
		args = append(args, *f.Status)
		i++
	}
	if f.Channel != nil {
		q += ` AND channel = $` + itoa(i)
		args = append(args, *f.Channel)
		i++
	}
	q += ` ORDER BY created_at DESC`

	rows, err := r.pool.Query(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []*Notification
	for rows.Next() {
		n := &Notification{}
		var varsRaw []byte
		if err := rows.Scan(
			&n.ID, &n.RecipientID, &n.TemplateID, &n.Channel, &varsRaw, &n.Status,
			&n.SourceDomain, &n.SourceID, &n.ScheduledAt, &n.SentAt, &n.ReadAt,
			&n.RetryCount, &n.ErrorMessage, &n.CreatedAt,
		); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(varsRaw, &n.Variables); err != nil {
			return nil, err
		}
		list = append(list, n)
	}
	return list, rows.Err()
}

func (r *pgRepository) UpdateStatus(ctx context.Context, id uuid.UUID, status NotifStatus, sentAt *time.Time, errMsg *string) error {
	const q = `UPDATE notification.notifications SET status=$1, sent_at=$2, error_message=$3 WHERE id=$4`
	tag, err := r.pool.Exec(ctx, q, status, sentAt, errMsg, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *pgRepository) MarkRead(ctx context.Context, id uuid.UUID, userID uuid.UUID) error {
	const q = `UPDATE notification.notifications
		SET status='read', read_at=now()
		WHERE id=$1 AND recipient_id=$2 AND channel='in_app'`
	tag, err := r.pool.Exec(ctx, q, id, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}

func (r *pgRepository) CountUnread(ctx context.Context, userID uuid.UUID) (int, error) {
	const q = `SELECT COUNT(*) FROM notification.notifications
		WHERE recipient_id=$1 AND channel='in_app' AND status != 'read'`
	var count int
	err := r.pool.QueryRow(ctx, q, userID).Scan(&count)
	return count, err
}

func (r *pgRepository) ListPending(ctx context.Context, now time.Time, limit int) ([]*Notification, error) {
	const q = `SELECT id, recipient_id, template_id, channel, variables, status,
		source_domain, source_id, scheduled_at, sent_at, read_at, retry_count, error_message, created_at
		FROM notification.notifications
		WHERE status='pending' AND (scheduled_at IS NULL OR scheduled_at <= $1)
		ORDER BY created_at ASC LIMIT $2`
	rows, err := r.pool.Query(ctx, q, now, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []*Notification
	for rows.Next() {
		n := &Notification{}
		var varsRaw []byte
		if err := rows.Scan(
			&n.ID, &n.RecipientID, &n.TemplateID, &n.Channel, &varsRaw, &n.Status,
			&n.SourceDomain, &n.SourceID, &n.ScheduledAt, &n.SentAt, &n.ReadAt,
			&n.RetryCount, &n.ErrorMessage, &n.CreatedAt,
		); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(varsRaw, &n.Variables); err != nil {
			return nil, err
		}
		list = append(list, n)
	}
	return list, rows.Err()
}

func (r *pgRepository) IncrementRetry(ctx context.Context, id uuid.UUID, errMsg string) error {
	const q = `UPDATE notification.notifications
		SET retry_count = retry_count + 1, error_message = $1, status = CASE
			WHEN retry_count + 1 >= $2 THEN 'failed'
			ELSE status
		END
		WHERE id = $3`
	_, err := r.pool.Exec(ctx, q, errMsg, MaxRetryCount, id)
	return err
}

// ── Preferences ───────────────────────────────────────────────────────────────

func (r *pgRepository) UpsertPreference(ctx context.Context, p *NotificationPreference) error {
	const q = `
		INSERT INTO notification.preferences (user_id, template_key, channel, enabled)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id, template_key, channel) DO UPDATE SET enabled = EXCLUDED.enabled
		RETURNING id`
	return r.pool.QueryRow(ctx, q, p.UserID, p.TemplateKey, p.Channel, p.Enabled).Scan(&p.ID)
}

func (r *pgRepository) GetPreference(ctx context.Context, userID uuid.UUID, key string, ch Channel) (*NotificationPreference, error) {
	const q = `SELECT id, user_id, template_key, channel, enabled
		FROM notification.preferences WHERE user_id=$1 AND template_key=$2 AND channel=$3`
	p := &NotificationPreference{}
	err := r.pool.QueryRow(ctx, q, userID, key, ch).Scan(&p.ID, &p.UserID, &p.TemplateKey, &p.Channel, &p.Enabled)
	if err == pgx.ErrNoRows {
		return nil, apperrors.ErrNotFound
	}
	return p, err
}

func (r *pgRepository) ListPreferences(ctx context.Context, userID uuid.UUID) ([]*NotificationPreference, error) {
	const q = `SELECT id, user_id, template_key, channel, enabled
		FROM notification.preferences WHERE user_id=$1 ORDER BY template_key, channel`
	rows, err := r.pool.Query(ctx, q, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []*NotificationPreference
	for rows.Next() {
		p := &NotificationPreference{}
		if err := rows.Scan(&p.ID, &p.UserID, &p.TemplateKey, &p.Channel, &p.Enabled); err != nil {
			return nil, err
		}
		list = append(list, p)
	}
	return list, rows.Err()
}

// ── helpers ───────────────────────────────────────────────────────────────────

func itoa(i int) string {
	const digits = "0123456789"
	if i < 10 {
		return string(digits[i])
	}
	b := []byte{}
	for i > 0 {
		b = append([]byte{digits[i%10]}, b...)
		i /= 10
	}
	return string(b)
}
