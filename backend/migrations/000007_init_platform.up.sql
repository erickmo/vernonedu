-- ============================================================
-- Migration 000007: platform schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS platform;

CREATE TYPE platform.notification_channel AS ENUM ('email', 'in_app', 'push');
CREATE TYPE platform.notification_status AS ENUM ('pending', 'sent', 'failed', 'read');
CREATE TYPE platform.notification_source_domain AS ENUM (
  'payment', 'enrollment', 'team_member', 'calendar', 'partner', 'manual'
);

CREATE TABLE platform.notification_templates (
  id         UUID                          PRIMARY KEY DEFAULT gen_random_uuid(),
  key        TEXT                          NOT NULL,
  channel    platform.notification_channel NOT NULL,
  subject    TEXT                          NULL,
  body       TEXT                          NOT NULL,
  is_active  BOOLEAN                       NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  CONSTRAINT uq_template_key_channel UNIQUE (key, channel)
);
SELECT attach_updated_at_trigger('platform','notification_templates');
CREATE INDEX idx_notif_templates_key ON platform.notification_templates(key);

CREATE TABLE platform.notifications (
  id            UUID                               PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  UUID                               NOT NULL REFERENCES identity.users(id) ON DELETE CASCADE,
  template_id   UUID                               NOT NULL REFERENCES platform.notification_templates(id) ON DELETE RESTRICT,
  channel       platform.notification_channel      NOT NULL,
  variables     JSONB                              NOT NULL DEFAULT '{}',
  status        platform.notification_status       NOT NULL DEFAULT 'pending',
  source_domain platform.notification_source_domain NULL,
  source_id     UUID                               NULL,
  scheduled_at  TIMESTAMPTZ                        NULL,
  sent_at       TIMESTAMPTZ                        NULL,
  read_at       TIMESTAMPTZ                        NULL,
  retry_count   INTEGER                            NOT NULL DEFAULT 0,
  error_message TEXT                               NULL,
  created_at    TIMESTAMPTZ                        NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ                        NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('platform','notifications');
CREATE INDEX idx_notifications_recipient ON platform.notifications(recipient_id);
CREATE INDEX idx_notifications_status    ON platform.notifications(status);
CREATE INDEX idx_notifications_scheduled ON platform.notifications(scheduled_at) WHERE scheduled_at IS NOT NULL AND status = 'pending';
CREATE INDEX idx_notifications_source    ON platform.notifications(source_domain, source_id) WHERE source_domain IS NOT NULL;

CREATE TABLE platform.notification_preferences (
  id           UUID                          PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID                          NOT NULL REFERENCES identity.users(id) ON DELETE CASCADE,
  template_key TEXT                          NOT NULL,
  channel      platform.notification_channel NOT NULL,
  enabled      BOOLEAN                       NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  CONSTRAINT uq_notif_pref UNIQUE (user_id, template_key, channel)
);
SELECT attach_updated_at_trigger('platform','notification_preferences');
CREATE INDEX idx_notif_prefs_user ON platform.notification_preferences(user_id);
