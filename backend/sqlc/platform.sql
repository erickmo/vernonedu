-- name: GetTemplateByKeyAndChannel :one
SELECT * FROM platform.notification_templates
WHERE key = $1 AND channel = $2 AND is_active = TRUE;

-- name: CreateNotification :one
INSERT INTO platform.notifications
  (id, recipient_id, template_id, channel, variables, status, source_domain, source_id, scheduled_at)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
RETURNING *;

-- name: ListPendingNotifications :many
SELECT * FROM platform.notifications
WHERE status = 'pending' AND (scheduled_at IS NULL OR scheduled_at <= now())
ORDER BY created_at
LIMIT $1;

-- name: UpdateNotificationStatus :exec
UPDATE platform.notifications SET status = $1 WHERE id = $2;

-- name: ListNotificationsByRecipient :many
SELECT * FROM platform.notifications
WHERE recipient_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3;

-- name: MarkNotificationRead :exec
UPDATE platform.notifications SET status='read', read_at=now()
WHERE id = $1 AND status = 'sent';
