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

-- name: CreateEvent :one
INSERT INTO platform.calendar_events
  (title, description, event_type, start_at, end_at, location, rrule, source_domain, source_id, created_by)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
RETURNING *;

-- name: GetEvent :one
SELECT * FROM platform.calendar_events WHERE id = $1;

-- name: ListEventsByUser :many
SELECT DISTINCT e.*
FROM platform.calendar_events e
LEFT JOIN platform.calendar_attendees a ON a.event_id = e.id
WHERE e.created_by = $1 OR a.user_id = $1
ORDER BY e.start_at
LIMIT $2 OFFSET $3;

-- name: UpdateEvent :one
UPDATE platform.calendar_events
SET title       = $2,
    description = $3,
    event_type  = $4,
    start_at    = $5,
    end_at      = $6,
    location    = $7,
    rrule       = $8
WHERE id = $1
RETURNING *;

-- name: DeleteEvent :exec
DELETE FROM platform.calendar_events WHERE id = $1;

-- name: AddAttendee :one
INSERT INTO platform.calendar_attendees (event_id, user_id, role, rsvp_status)
VALUES ($1,$2,$3,$4)
RETURNING *;

-- name: RemoveAttendee :exec
DELETE FROM platform.calendar_attendees WHERE event_id = $1 AND user_id = $2;

-- name: ListAttendeesByEvent :many
SELECT * FROM platform.calendar_attendees WHERE event_id = $1 ORDER BY created_at;

-- name: ListEventsNeedingReminder :many
SELECT * FROM platform.calendar_events
WHERE event_type = 'class_session'
  AND reminder_fired_at IS NULL
  AND start_at BETWEEN now() + interval '60 minutes' AND now() + interval '65 minutes';

-- name: MarkReminderFired :exec
UPDATE platform.calendar_events SET reminder_fired_at = now() WHERE id = $1;

-- name: UpsertCalendarSync :one
INSERT INTO platform.calendar_sync
  (user_id, provider, access_token_enc, refresh_token_enc, token_expires_at, external_calendar_id)
VALUES ($1,$2,$3,$4,$5,$6)
ON CONFLICT (user_id) DO UPDATE
SET provider             = EXCLUDED.provider,
    access_token_enc     = EXCLUDED.access_token_enc,
    refresh_token_enc    = EXCLUDED.refresh_token_enc,
    token_expires_at     = EXCLUDED.token_expires_at,
    external_calendar_id = EXCLUDED.external_calendar_id,
    updated_at           = now()
RETURNING *;

-- name: GetCalendarSyncByUser :one
SELECT * FROM platform.calendar_sync WHERE user_id = $1;
