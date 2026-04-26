-- ============================================================
-- Migration 000003: enrollment schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS enrollment;

CREATE TYPE enrollment.enrollment_format AS ENUM (
  'regular', 'private', 'inhouse_training', 'inschool_program'
);
CREATE TYPE enrollment.enrollment_mode AS ENUM ('online', 'offline');
CREATE TYPE enrollment.payer_type AS ENUM ('student', 'partner');
CREATE TYPE enrollment.payment_status AS ENUM ('pending', 'partial', 'paid', 'overdue');
CREATE TYPE enrollment.completion_status AS ENUM ('ongoing', 'completed', 'dropped');
CREATE TYPE enrollment.enrollment_source AS ENUM ('b2b', 'b2c');
CREATE TYPE enrollment.discount_type AS ENUM ('fixed_amount', 'percentage', 'fixed_final_price');
CREATE TYPE enrollment.calendar_event_type AS ENUM (
  'class_session', 'staff_meeting', 'admin_deadline',
  'payment_due', 'facilitator_schedule', 'partner_meeting'
);
CREATE TYPE enrollment.calendar_source_domain AS ENUM (
  'course', 'enrollment', 'payment', 'team_member', 'partner', 'manual'
);
CREATE TYPE enrollment.attendee_role AS ENUM ('organizer', 'attendee');
CREATE TYPE enrollment.rsvp_status AS ENUM ('pending', 'accepted', 'declined');
CREATE TYPE enrollment.calendar_provider AS ENUM ('google_calendar');

CREATE TABLE enrollment.vouchers (
  id              UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  code            TEXT                      NOT NULL UNIQUE,
  discount_type   enrollment.discount_type  NOT NULL,
  discount_value  NUMERIC(12,2)             NOT NULL,
  assigned_to     UUID                      NULL REFERENCES identity.students(id) ON DELETE SET NULL,
  course_id       UUID                      NULL REFERENCES catalog.courses(id) ON DELETE SET NULL,
  course_batch_id UUID                      NULL REFERENCES catalog.course_batches(id) ON DELETE SET NULL,
  valid_from      DATE                      NOT NULL,
  valid_until     DATE                      NULL,
  max_uses        INTEGER                   NULL CHECK (max_uses > 0),
  used_count      INTEGER                   NOT NULL DEFAULT 0,
  is_active       BOOLEAN                   NOT NULL DEFAULT TRUE,
  created_by      UUID                      NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at      TIMESTAMPTZ               NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ               NOT NULL DEFAULT now(),
  CONSTRAINT chk_voucher_used_max CHECK (used_count <= COALESCE(max_uses, used_count + 1)),
  CONSTRAINT chk_voucher_pct_range CHECK (
    discount_type <> 'percentage' OR (discount_value >= 0 AND discount_value <= 100)
  )
);
SELECT attach_updated_at_trigger('enrollment','vouchers');
CREATE INDEX idx_vouchers_code        ON enrollment.vouchers(code);
CREATE INDEX idx_vouchers_assigned_to ON enrollment.vouchers(assigned_to) WHERE assigned_to IS NOT NULL;

CREATE TABLE enrollment.enrollments (
  id                UUID                          PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id        UUID                          NOT NULL REFERENCES identity.students(id) ON DELETE RESTRICT,
  course_batch_id   UUID                          NOT NULL REFERENCES catalog.course_batches(id) ON DELETE RESTRICT,
  format            enrollment.enrollment_format  NOT NULL,
  mode              enrollment.enrollment_mode    NOT NULL,
  payer             enrollment.payer_type         NOT NULL,
  partner_id        UUID                          NULL,
  franchisee_id     UUID                          NULL,
  price             NUMERIC(12,2)                 NOT NULL DEFAULT 0.00,
  final_price       NUMERIC(12,2)                 NOT NULL DEFAULT 0.00,
  voucher_id        UUID                          NULL REFERENCES enrollment.vouchers(id) ON DELETE SET NULL,
  credit_applied    NUMERIC(12,2)                 NOT NULL DEFAULT 0.00,
  student_credit_id UUID                          NULL,
  payment_status    enrollment.payment_status     NOT NULL DEFAULT 'pending',
  completion_status enrollment.completion_status  NOT NULL DEFAULT 'ongoing',
  source            enrollment.enrollment_source  NOT NULL,
  created_at        TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  CONSTRAINT uq_enrollment UNIQUE (student_id, course_batch_id)
);
SELECT attach_updated_at_trigger('enrollment','enrollments');
CREATE INDEX idx_enrollments_student ON enrollment.enrollments(student_id);
CREATE INDEX idx_enrollments_batch   ON enrollment.enrollments(course_batch_id);
CREATE INDEX idx_enrollments_partner ON enrollment.enrollments(partner_id) WHERE partner_id IS NOT NULL;
CREATE INDEX idx_enrollments_status  ON enrollment.enrollments(payment_status, completion_status);

CREATE TABLE enrollment.voucher_usages (
  id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  voucher_id     UUID          NOT NULL REFERENCES enrollment.vouchers(id) ON DELETE RESTRICT,
  enrollment_id  UUID          NOT NULL UNIQUE REFERENCES enrollment.enrollments(id) ON DELETE RESTRICT,
  original_price NUMERIC(12,2) NOT NULL,
  final_price    NUMERIC(12,2) NOT NULL,
  used_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
  created_by     UUID          NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT
);
CREATE INDEX idx_voucher_usages_voucher ON enrollment.voucher_usages(voucher_id);

CREATE TABLE enrollment.calendar_events (
  id                       UUID                              PRIMARY KEY DEFAULT gen_random_uuid(),
  title                    TEXT                              NOT NULL,
  description              TEXT                              NULL,
  event_type               enrollment.calendar_event_type    NOT NULL,
  start_at                 TIMESTAMPTZ                       NOT NULL,
  end_at                   TIMESTAMPTZ                       NOT NULL,
  is_all_day               BOOLEAN                           NOT NULL DEFAULT FALSE,
  recurrence_rule          TEXT                              NULL,
  location                 TEXT                              NULL,
  source_domain            enrollment.calendar_source_domain NULL,
  source_id                UUID                              NULL,
  partnership_agreement_id UUID                              NULL,
  agenda                   TEXT                              NULL,
  meeting_notes            TEXT                              NULL,
  created_by               UUID                              NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at               TIMESTAMPTZ                       NOT NULL DEFAULT now(),
  updated_at               TIMESTAMPTZ                       NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('enrollment','calendar_events');
CREATE INDEX idx_cal_events_type   ON enrollment.calendar_events(event_type);
CREATE INDEX idx_cal_events_start  ON enrollment.calendar_events(start_at);
CREATE INDEX idx_cal_events_source ON enrollment.calendar_events(source_domain, source_id) WHERE source_domain IS NOT NULL;

CREATE TABLE enrollment.calendar_attendees (
  id          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    UUID                     NOT NULL REFERENCES enrollment.calendar_events(id) ON DELETE CASCADE,
  user_id     UUID                     NOT NULL REFERENCES identity.users(id) ON DELETE CASCADE,
  role        enrollment.attendee_role NOT NULL DEFAULT 'attendee',
  rsvp_status enrollment.rsvp_status  NOT NULL DEFAULT 'pending',
  created_at  TIMESTAMPTZ              NOT NULL DEFAULT now(),
  CONSTRAINT uq_attendee_event UNIQUE (event_id, user_id)
);
CREATE INDEX idx_cal_attendees_user ON enrollment.calendar_attendees(user_id);

CREATE TABLE enrollment.calendar_syncs (
  id               UUID                         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID                         NOT NULL UNIQUE REFERENCES identity.users(id) ON DELETE CASCADE,
  provider         enrollment.calendar_provider NOT NULL DEFAULT 'google_calendar',
  access_token     TEXT                         NOT NULL,
  refresh_token    TEXT                         NOT NULL,
  last_synced_at   TIMESTAMPTZ                  NULL,
  token_expires_at TIMESTAMPTZ                  NULL,
  created_at       TIMESTAMPTZ                  NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ                  NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('enrollment','calendar_syncs');
