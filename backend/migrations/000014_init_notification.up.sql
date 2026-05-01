CREATE SCHEMA IF NOT EXISTS notification;

CREATE TYPE notification.channel AS ENUM ('email', 'in_app', 'push');
CREATE TYPE notification.notif_status AS ENUM ('pending', 'sent', 'failed', 'read');

CREATE TABLE notification.templates (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key        TEXT NOT NULL,
  channel    notification.channel NOT NULL,
  subject    TEXT NULL,
  body       TEXT NOT NULL,
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(key, channel)
);

CREATE TABLE notification.notifications (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id   UUID NOT NULL REFERENCES identity.users(id),
  template_id    UUID NOT NULL REFERENCES notification.templates(id),
  channel        notification.channel NOT NULL,
  variables      JSONB NOT NULL DEFAULT '{}',
  status         notification.notif_status NOT NULL DEFAULT 'pending',
  source_domain  TEXT NULL,
  source_id      UUID NULL,
  scheduled_at   TIMESTAMPTZ NULL,
  sent_at        TIMESTAMPTZ NULL,
  read_at        TIMESTAMPTZ NULL,
  retry_count    INT NOT NULL DEFAULT 0,
  error_message  TEXT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notif_recipient ON notification.notifications(recipient_id);
CREATE INDEX idx_notif_status    ON notification.notifications(status);
CREATE INDEX idx_notif_scheduled ON notification.notifications(scheduled_at) WHERE scheduled_at IS NOT NULL;

CREATE TABLE notification.preferences (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES identity.users(id),
  template_key TEXT NOT NULL,
  channel      notification.channel NOT NULL,
  enabled      BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE(user_id, template_key, channel)
);

CREATE INDEX idx_notif_pref_user ON notification.preferences(user_id);

SELECT attach_updated_at_trigger('notification', 'templates');
