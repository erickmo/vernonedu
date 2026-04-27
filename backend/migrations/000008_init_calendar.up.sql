-- ============================================================
-- Migration 000008: calendar tables (platform schema)
-- ============================================================

CREATE TYPE platform.calendar_event_type AS ENUM (
  'class_session','payment_due','partner_meeting','manual_internal','manual_personal'
);

CREATE TYPE platform.calendar_rsvp_status AS ENUM (
  'pending','accepted','declined','tentative'
);

CREATE TABLE platform.calendar_events (
  id                UUID                         PRIMARY KEY DEFAULT gen_random_uuid(),
  title             TEXT                         NOT NULL,
  description       TEXT                         NULL,
  event_type        platform.calendar_event_type NOT NULL,
  start_at          TIMESTAMPTZ                  NOT NULL,
  end_at            TIMESTAMPTZ                  NOT NULL,
  location          TEXT                         NULL,
  rrule             TEXT                         NULL,
  source_domain     TEXT                         NULL,
  source_id         UUID                         NULL,
  created_by        UUID                         NULL,
  reminder_fired_at TIMESTAMPTZ                  NULL,
  created_at        TIMESTAMPTZ                  NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ                  NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('platform','calendar_events');
CREATE INDEX idx_calendar_events_start_at ON platform.calendar_events(start_at);
CREATE INDEX idx_calendar_events_source   ON platform.calendar_events(source_domain, source_id);

CREATE TABLE platform.calendar_attendees (
  id          UUID                          PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    UUID                          NOT NULL REFERENCES platform.calendar_events(id) ON DELETE CASCADE,
  user_id     UUID                          NOT NULL,
  role        TEXT                          NOT NULL,
  rsvp_status platform.calendar_rsvp_status NOT NULL DEFAULT 'pending',
  created_at  TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  CONSTRAINT uq_calendar_attendee UNIQUE (event_id, user_id)
);
CREATE INDEX idx_calendar_attendees_user ON platform.calendar_attendees(user_id);

CREATE TABLE platform.calendar_sync (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID        NOT NULL UNIQUE,
  provider             TEXT        NOT NULL,
  access_token_enc     BYTEA       NOT NULL,
  refresh_token_enc    BYTEA       NOT NULL,
  token_expires_at     TIMESTAMPTZ NOT NULL,
  external_calendar_id TEXT        NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('platform','calendar_sync');
