CREATE TABLE IF NOT EXISTS notifications (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type         VARCHAR(50)  NOT NULL,
    title        VARCHAR(255) NOT NULL,
    body         TEXT         NOT NULL,
    channel      VARCHAR(50)  NOT NULL DEFAULT 'in_app',
    metadata     JSONB,
    read_at      TIMESTAMPTZ,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id   ON notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_read ON notifications(recipient_id, read_at);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at     ON notifications(created_at DESC);
