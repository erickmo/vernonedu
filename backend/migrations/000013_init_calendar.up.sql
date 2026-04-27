CREATE SCHEMA IF NOT EXISTS calendar;

CREATE TYPE calendar.event_type AS ENUM (
  'class_session', 'staff_meeting', 'admin_deadline',
  'payment_due', 'facilitator_schedule', 'partner_meeting'
);

CREATE TYPE calendar.source_domain AS ENUM (
  'course', 'enrollment', 'payment', 'team_member', 'partner', 'manual'
);

CREATE TYPE calendar.attendee_role AS ENUM ('organizer', 'attendee');
CREATE TYPE calendar.rsvp_status   AS ENUM ('pending', 'accepted', 'declined');
CREATE TYPE calendar.sync_provider AS ENUM ('google_calendar');

CREATE TABLE calendar.events (
  id                       UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  title                    TEXT                    NOT NULL,
  description              TEXT                    NULL,
  event_type               calendar.event_type     NOT NULL,
  start_at                 TIMESTAMPTZ             NOT NULL,
  end_at                   TIMESTAMPTZ             NOT NULL,
  is_all_day               BOOLEAN                 NOT NULL DEFAULT FALSE,
  recurrence_rule          TEXT                    NULL,
  location                 TEXT                    NULL,
  source_domain            calendar.source_domain  NULL,
  source_id                UUID                    NULL,
  partnership_agreement_id UUID                    NULL,
  agenda                   TEXT                    NULL,
  meeting_notes            TEXT                    NULL,
  class_reminder_sent      BOOLEAN                 NOT NULL DEFAULT FALSE,
  created_by               UUID                    NOT NULL REFERENCES identity.users(id),
  created_at               TIMESTAMPTZ             NOT NULL DEFAULT now()
);

CREATE INDEX idx_calendar_events_source  ON calendar.events(source_domain, source_id) WHERE source_id IS NOT NULL;
CREATE INDEX idx_calendar_events_start   ON calendar.events(start_at);
CREATE INDEX idx_calendar_events_type    ON calendar.events(event_type);
CREATE INDEX idx_calendar_events_creator ON calendar.events(created_by);

CREATE TABLE calendar.attendees (
  id          UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    UUID                    NOT NULL REFERENCES calendar.events(id) ON DELETE CASCADE,
  user_id     UUID                    NOT NULL REFERENCES identity.users(id),
  role        calendar.attendee_role  NOT NULL DEFAULT 'attendee',
  rsvp_status calendar.rsvp_status   NOT NULL DEFAULT 'pending',
  UNIQUE(event_id, user_id)
);

CREATE INDEX idx_calendar_attendees_event ON calendar.attendees(event_id);
CREATE INDEX idx_calendar_attendees_user  ON calendar.attendees(user_id);

CREATE TABLE calendar.syncs (
  id               UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID                    NOT NULL UNIQUE REFERENCES identity.users(id),
  provider         calendar.sync_provider  NOT NULL DEFAULT 'google_calendar',
  access_token     TEXT                    NOT NULL,
  refresh_token    TEXT                    NOT NULL,
  last_synced_at   TIMESTAMPTZ             NULL,
  token_expires_at TIMESTAMPTZ             NULL,
  created_at       TIMESTAMPTZ             NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ             NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('calendar', 'syncs');
