package database

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/notification"
)

// NotificationRepository implements both notification.WriteRepository and notification.ReadRepository.
type NotificationRepository struct {
	db *sqlx.DB
}

func NewNotificationRepository(db *sqlx.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

type notificationRecord struct {
	ID          uuid.UUID      `db:"id"`
	RecipientID uuid.UUID      `db:"recipient_id"`
	Type        string         `db:"type"`
	Title       string         `db:"title"`
	Body        string         `db:"body"`
	Channel     string         `db:"channel"`
	Metadata    []byte         `db:"metadata"`
	ReadAt      *time.Time     `db:"read_at"`
	CreatedAt   time.Time      `db:"created_at"`
}

func (rec *notificationRecord) toDomain() *notification.Notification {
	var metadata map[string]interface{}
	if len(rec.Metadata) > 0 {
		_ = json.Unmarshal(rec.Metadata, &metadata)
	}
	return &notification.Notification{
		ID:          rec.ID,
		RecipientID: rec.RecipientID,
		Type:        rec.Type,
		Title:       rec.Title,
		Body:        rec.Body,
		Channel:     rec.Channel,
		Metadata:    metadata,
		ReadAt:      rec.ReadAt,
		CreatedAt:   rec.CreatedAt,
	}
}

// Save persists a new notification.
func (r *NotificationRepository) Save(ctx context.Context, n *notification.Notification) error {
	metaJSON, err := json.Marshal(n.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal notification metadata: %w", err)
	}

	query := `
		INSERT INTO notifications (id, recipient_id, type, title, body, channel, metadata, read_at, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err = r.db.ExecContext(ctx, query,
		n.ID, n.RecipientID, n.Type, n.Title, n.Body, n.Channel,
		metaJSON, n.ReadAt, n.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save notification: %w", err)
	}
	return nil
}

// MarkRead marks a single notification as read, scoped to the recipient.
func (r *NotificationRepository) MarkRead(ctx context.Context, id, recipientID uuid.UUID) error {
	query := `
		UPDATE notifications
		SET read_at = NOW()
		WHERE id = $1 AND recipient_id = $2 AND read_at IS NULL
	`
	result, err := r.db.ExecContext(ctx, query, id, recipientID)
	if err != nil {
		return fmt.Errorf("failed to mark notification read: %w", err)
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return notification.ErrNotificationNotFound
	}
	return nil
}

// MarkAllRead marks all unread notifications for a recipient as read.
func (r *NotificationRepository) MarkAllRead(ctx context.Context, recipientID uuid.UUID) error {
	query := `
		UPDATE notifications
		SET read_at = NOW()
		WHERE recipient_id = $1 AND read_at IS NULL
	`
	_, err := r.db.ExecContext(ctx, query, recipientID)
	if err != nil {
		return fmt.Errorf("failed to mark all notifications as read: %w", err)
	}
	return nil
}

// GetByID retrieves a single notification by ID.
func (r *NotificationRepository) GetByID(ctx context.Context, id uuid.UUID) (*notification.Notification, error) {
	var rec notificationRecord
	query := `
		SELECT id, recipient_id, type, title, body, channel,
		       COALESCE(metadata, '{}'::jsonb) AS metadata,
		       read_at, created_at
		FROM notifications
		WHERE id = $1
	`
	if err := r.db.GetContext(ctx, &rec, query, id); err != nil {
		if err == sql.ErrNoRows {
			return nil, notification.ErrNotificationNotFound
		}
		return nil, fmt.Errorf("failed to get notification: %w", err)
	}
	return rec.toDomain(), nil
}

// ListByRecipient returns paginated notifications for a recipient with optional filters.
func (r *NotificationRepository) ListByRecipient(
	ctx context.Context,
	recipientID uuid.UUID,
	offset, limit int,
	onlyUnread bool,
	notifType string,
) ([]*notification.Notification, int, error) {
	// Build dynamic WHERE clause
	where := "WHERE recipient_id = $1"
	args := []interface{}{recipientID}
	idx := 2

	if onlyUnread {
		where += " AND read_at IS NULL"
	}
	if notifType != "" {
		where += fmt.Sprintf(" AND type = $%d", idx)
		args = append(args, notifType)
		idx++
	}

	// Count total
	var total int
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM notifications %s", where)
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count notifications: %w", err)
	}

	// Paginate
	listQuery := fmt.Sprintf(`
		SELECT id, recipient_id, type, title, body, channel,
		       COALESCE(metadata, '{}'::jsonb) AS metadata,
		       read_at, created_at
		FROM notifications
		%s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, where, idx, idx+1)
	args = append(args, limit, offset)

	var recs []notificationRecord
	if err := r.db.SelectContext(ctx, &recs, listQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to list notifications: %w", err)
	}

	items := make([]*notification.Notification, len(recs))
	for i, rec := range recs {
		items[i] = rec.toDomain()
	}
	return items, total, nil
}

// GetUnreadCount returns the count of unread notifications for a recipient.
func (r *NotificationRepository) GetUnreadCount(ctx context.Context, recipientID uuid.UUID) (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM notifications WHERE recipient_id = $1 AND read_at IS NULL`
	if err := r.db.GetContext(ctx, &count, query, recipientID); err != nil {
		return 0, fmt.Errorf("failed to get unread count: %w", err)
	}
	return count, nil
}
