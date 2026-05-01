-- ============================================================
-- VernonEdu2 — Initial Schema Migration
-- PostgreSQL 16+  |  Modular Monolith  |  7 bounded contexts
-- ============================================================

-- ------------------------------------------------------------
-- Shared updated_at trigger function (created once, reused)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Macro so each table only needs one line to wire the trigger
-- Usage: SELECT attach_updated_at_trigger('schema', 'table');
CREATE OR REPLACE FUNCTION attach_updated_at_trigger(
  p_schema TEXT,
  p_table  TEXT
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE format(
    'CREATE TRIGGER trg_%2$s_updated_at
     BEFORE UPDATE ON %1$I.%2$I
     FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
    p_schema, p_table
  );
END;
$$;

-- ============================================================
-- SCHEMA: identity
-- users, team_members, facilitator_profiles,
-- facilitator_proposals, fee_tiers, departments
-- ============================================================
CREATE SCHEMA IF NOT EXISTS identity;

-- ENUMS -------------------------------------------------------
CREATE TYPE identity.user_role AS ENUM (
  'ceo', 'finance', 'academic_leader', 'dept_leader',
  'course_creator', 'vernonedu_admin', 'admin',
  'student', 'franchisee'
);

CREATE TYPE identity.student_source AS ENUM ('b2b', 'b2c');

CREATE TYPE identity.gender_type AS ENUM ('male', 'female');

CREATE TYPE identity.id_card_type AS ENUM ('ktp', 'passport', 'sim');

CREATE TYPE identity.employment_status AS ENUM ('active', 'inactive', 'on_leave');

CREATE TYPE identity.proposal_review_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TYPE identity.fee_basis AS ENUM ('per_class', 'per_course', 'both');

-- TABLES ------------------------------------------------------

CREATE TABLE identity.users (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email             TEXT        NOT NULL UNIQUE,
  password_hash     TEXT        NOT NULL,
  role              identity.user_role NOT NULL,
  is_active         BOOLEAN     NOT NULL DEFAULT TRUE,
  device_push_token TEXT        NULL,  -- for push notifications
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('identity','users');

CREATE INDEX idx_users_role     ON identity.users(role);
CREATE INDEX idx_users_email    ON identity.users(email);

-- Students are users with role = 'student'
CREATE TABLE identity.students (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL UNIQUE REFERENCES identity.users(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  email      TEXT        NOT NULL,  -- denormalised for fast lookups
  phone      TEXT        NOT NULL,
  source     identity.student_source NOT NULL DEFAULT 'b2c',
  partner_id UUID        NULL,      -- FK to partnerships.partners; set for B2B
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('identity','students');

CREATE INDEX idx_students_user_id   ON identity.students(user_id);
CREATE INDEX idx_students_partner_id ON identity.students(partner_id) WHERE partner_id IS NOT NULL;

CREATE TABLE identity.student_profiles (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       UUID        NOT NULL UNIQUE REFERENCES identity.students(id) ON DELETE CASCADE,
  date_of_birth    DATE        NULL,
  gender           identity.gender_type NULL,
  id_type          identity.id_card_type NULL,
  id_number        TEXT        NULL,
  address          TEXT        NULL,
  city             TEXT        NULL,
  province         TEXT        NULL,
  postal_code      TEXT        NULL,
  profile_complete BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('identity','student_profiles');

CREATE TABLE identity.departments (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT        NOT NULL,
  leader_id  UUID        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
  created_by UUID        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('identity','departments');

CREATE INDEX idx_departments_leader ON identity.departments(leader_id);

CREATE TABLE identity.team_members (
  id                UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID                      NOT NULL UNIQUE REFERENCES identity.users(id) ON DELETE CASCADE,
  full_name         TEXT                      NOT NULL,
  phone             TEXT                      NOT NULL,
  department_id     UUID                      NULL REFERENCES identity.departments(id) ON DELETE SET NULL,
  role              identity.user_role        NOT NULL,
  employment_status identity.employment_status NOT NULL DEFAULT 'active',
  joined_at         DATE                      NOT NULL,
  is_facilitator    BOOLEAN                   NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ               NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ               NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('identity','team_members');

CREATE INDEX idx_team_members_department ON identity.team_members(department_id);
CREATE INDEX idx_team_members_role       ON identity.team_members(role);

CREATE TABLE identity.facilitator_profiles (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  team_member_id UUID        NOT NULL UNIQUE REFERENCES identity.team_members(id) ON DELETE CASCADE,
  specialization TEXT        NOT NULL,
  bio            TEXT        NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('identity','facilitator_profiles');

CREATE TABLE identity.fee_tiers (
  id                UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  name              TEXT             NOT NULL,
  amount_per_class  NUMERIC(12,2)    NULL,
  amount_per_course NUMERIC(12,2)    NULL,
  created_by        UUID             NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  is_active         BOOLEAN          NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ      NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ      NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('identity','fee_tiers');

CREATE TABLE identity.facilitator_proposals (
  id                          UUID                              PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id                   UUID                              NOT NULL,   -- FK wired after catalog schema
  proposed_by                 UUID                              NOT NULL REFERENCES identity.team_members(id) ON DELETE RESTRICT,
  facilitator_id              UUID                              NOT NULL REFERENCES identity.team_members(id) ON DELETE RESTRICT,
  fee_tier_id                 UUID                              NOT NULL REFERENCES identity.fee_tiers(id) ON DELETE RESTRICT,
  fee_basis                   identity.fee_basis                NOT NULL,
  dept_leader_status          identity.proposal_review_status   NOT NULL DEFAULT 'pending',
  dept_leader_reviewed_at     TIMESTAMPTZ                       NULL,
  dept_leader_note            TEXT                              NULL,
  academic_leader_status      identity.proposal_review_status   NOT NULL DEFAULT 'pending',
  academic_leader_reviewed_at TIMESTAMPTZ                       NULL,
  academic_leader_note        TEXT                              NULL,
  final_status                identity.proposal_review_status   NOT NULL DEFAULT 'pending',
  created_at                  TIMESTAMPTZ                       NOT NULL DEFAULT now(),
  updated_at                  TIMESTAMPTZ                       NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('identity','facilitator_proposals');

CREATE INDEX idx_proposals_course      ON identity.facilitator_proposals(course_id);
CREATE INDEX idx_proposals_facilitator ON identity.facilitator_proposals(facilitator_id);
CREATE INDEX idx_proposals_final_status ON identity.facilitator_proposals(final_status);

-- ============================================================
-- SCHEMA: catalog
-- courses, course_format_configs, course_cost_templates,
-- course_batches, classes, modules, module_versions,
-- module_assets, batch_module_configs
-- ============================================================
CREATE SCHEMA IF NOT EXISTS catalog;

-- ENUMS -------------------------------------------------------
CREATE TYPE catalog.course_format AS ENUM (
  'regular', 'private', 'inhouse_training', 'inschool_program'
);

CREATE TYPE catalog.delivery_mode AS ENUM ('online', 'offline');

CREATE TYPE catalog.batch_status AS ENUM ('draft', 'open', 'ongoing', 'closed');

CREATE TYPE catalog.cost_type AS ENUM ('fixed', 'percentage_of_revenue');

CREATE TYPE catalog.instructor_type AS ENUM ('course_creator', 'facilitator');

CREATE TYPE catalog.assigned_by_type AS ENUM ('course_creator_self', 'dept_leader');

CREATE TYPE catalog.module_status AS ENUM ('draft', 'published', 'archived');

CREATE TYPE catalog.asset_type AS ENUM ('video', 'pdf', 'document', 'link', 'image', 'other');

CREATE TYPE catalog.version_policy AS ENUM ('auto_latest', 'locked');

-- TABLES ------------------------------------------------------

CREATE TABLE catalog.courses (
  id                    UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT           NOT NULL,
  department_id         UUID           NOT NULL REFERENCES identity.departments(id) ON DELETE RESTRICT,
  course_creator_id     UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  base_price            NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  min_price             NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  profit_split_override JSONB          NULL,  -- {vernonedu_pct, course_creator_pct, dept_leader_pct, overridden_by, overridden_at}
  created_by            UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ    NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('catalog','courses');

CREATE INDEX idx_courses_department    ON catalog.courses(department_id);
CREATE INDEX idx_courses_creator       ON catalog.courses(course_creator_id);

CREATE TABLE catalog.course_format_configs (
  id           UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id    UUID               NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  format       catalog.course_format NOT NULL,
  is_enabled   BOOLEAN            NOT NULL DEFAULT TRUE,
  min_students INTEGER            NULL CHECK (min_students > 0),
  max_students INTEGER            NULL CHECK (max_students > 0),
  mode_online  BOOLEAN            NOT NULL DEFAULT FALSE,
  mode_offline BOOLEAN            NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ        NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ        NOT NULL DEFAULT now(),
  CONSTRAINT uq_course_format UNIQUE (course_id, format)
);

SELECT attach_updated_at_trigger('catalog','course_format_configs');

CREATE TABLE catalog.course_cost_templates (
  id         UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id  UUID               NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  label      TEXT               NOT NULL,
  amount     NUMERIC(12,2)      NOT NULL DEFAULT 0.00,
  cost_type  catalog.cost_type  NOT NULL DEFAULT 'fixed',
  created_at TIMESTAMPTZ        NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ        NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('catalog','course_cost_templates');

CREATE INDEX idx_cost_templates_course ON catalog.course_cost_templates(course_id);

CREATE TABLE catalog.course_batches (
  id                    UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id             UUID                  NOT NULL REFERENCES catalog.courses(id) ON DELETE RESTRICT,
  label                 TEXT                  NOT NULL,
  start_date            DATE                  NOT NULL,
  end_date              DATE                  NOT NULL,
  price                 NUMERIC(12,2)         NOT NULL DEFAULT 0.00,
  batch_bulk_price      NUMERIC(12,2)         NULL,
  status                catalog.batch_status  NOT NULL DEFAULT 'draft',
  web_registration_open BOOLEAN               NOT NULL DEFAULT FALSE,
  registration_open_at  TIMESTAMPTZ           NULL,
  registration_close_at TIMESTAMPTZ           NULL,
  created_by            UUID                  NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at            TIMESTAMPTZ           NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ           NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('catalog','course_batches');

CREATE INDEX idx_batches_course  ON catalog.course_batches(course_id);
CREATE INDEX idx_batches_status  ON catalog.course_batches(status);

CREATE TABLE catalog.classes (
  id              UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id UUID                      NOT NULL REFERENCES catalog.course_batches(id) ON DELETE CASCADE,
  title           TEXT                      NULL,
  session_date    DATE                      NOT NULL,
  start_time      TIME                      NOT NULL,
  end_time        TIME                      NOT NULL,
  mode            catalog.delivery_mode     NOT NULL,
  location        TEXT                      NULL,
  online_link     TEXT                      NULL,
  instructor_id   UUID                      NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  instructor_type catalog.instructor_type   NOT NULL,
  assigned_by     catalog.assigned_by_type  NOT NULL,
  created_at      TIMESTAMPTZ               NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ               NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('catalog','classes');

CREATE INDEX idx_classes_batch       ON catalog.classes(course_batch_id);
CREATE INDEX idx_classes_session_date ON catalog.classes(session_date);
CREATE INDEX idx_classes_instructor  ON catalog.classes(instructor_id);

CREATE TABLE catalog.modules (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id  UUID        NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  title      TEXT        NOT NULL,
  "order"    INTEGER     NOT NULL,
  is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
  created_by UUID        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('catalog','modules');

CREATE INDEX idx_modules_course ON catalog.modules(course_id);
CREATE UNIQUE INDEX uq_module_order ON catalog.modules(course_id, "order");

CREATE TABLE catalog.module_versions (
  id             UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id      UUID                  NOT NULL REFERENCES catalog.modules(id) ON DELETE CASCADE,
  version_number INTEGER               NOT NULL,
  title          TEXT                  NOT NULL,
  description    TEXT                  NULL,
  status         catalog.module_status NOT NULL DEFAULT 'draft',
  published_at   TIMESTAMPTZ           NULL,
  published_by   UUID                  NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  created_by     UUID                  NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at     TIMESTAMPTZ           NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ           NOT NULL DEFAULT now(),
  CONSTRAINT uq_module_version UNIQUE (module_id, version_number)
);

SELECT attach_updated_at_trigger('catalog','module_versions');

CREATE INDEX idx_module_versions_module  ON catalog.module_versions(module_id);
CREATE INDEX idx_module_versions_status  ON catalog.module_versions(status);

CREATE TABLE catalog.module_assets (
  id                UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
  module_version_id UUID               NOT NULL REFERENCES catalog.module_versions(id) ON DELETE CASCADE,
  title             TEXT               NOT NULL,
  asset_type        catalog.asset_type NOT NULL,
  url               TEXT               NOT NULL,
  size_bytes        BIGINT             NULL,
  "order"           INTEGER            NOT NULL,
  is_downloadable   BOOLEAN            NOT NULL DEFAULT FALSE,
  created_by        UUID               NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at        TIMESTAMPTZ        NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ        NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('catalog','module_assets');

CREATE INDEX idx_assets_version ON catalog.module_assets(module_version_id);

CREATE TABLE catalog.batch_module_configs (
  id              UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id UUID                    NOT NULL REFERENCES catalog.course_batches(id) ON DELETE CASCADE,
  module_id       UUID                    NOT NULL REFERENCES catalog.modules(id) ON DELETE CASCADE,
  version_policy  catalog.version_policy  NOT NULL DEFAULT 'auto_latest',
  locked_version_id UUID                  NULL REFERENCES catalog.module_versions(id) ON DELETE SET NULL,
  set_by          UUID                    NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at      TIMESTAMPTZ             NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ             NOT NULL DEFAULT now(),
  CONSTRAINT uq_batch_module UNIQUE (course_batch_id, module_id)
);

SELECT attach_updated_at_trigger('catalog','batch_module_configs');

CREATE TABLE catalog.course_budget_template_items (
  id             UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id      UUID           NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  label          TEXT           NOT NULL,
  category       TEXT           NULL,
  preset_amount  NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  overridable    BOOLEAN        NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ    NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('catalog','course_budget_template_items');

CREATE INDEX idx_budget_tmpl_course ON catalog.course_budget_template_items(course_id);

-- Wire deferred FK: facilitator_proposals.course_id
ALTER TABLE identity.facilitator_proposals
  ADD CONSTRAINT fk_proposal_course
  FOREIGN KEY (course_id) REFERENCES catalog.courses(id) ON DELETE RESTRICT;

-- ============================================================
-- SCHEMA: enrollment
-- enrollments, vouchers, voucher_usages,
-- calendar_events, calendar_attendees, calendar_syncs
-- ============================================================
CREATE SCHEMA IF NOT EXISTS enrollment;

-- ENUMS -------------------------------------------------------
CREATE TYPE enrollment.enrollment_format AS ENUM (
  'regular', 'private', 'inhouse_training', 'inschool_program'
);

CREATE TYPE enrollment.enrollment_mode AS ENUM ('online', 'offline');

CREATE TYPE enrollment.payer_type AS ENUM ('student', 'partner');

CREATE TYPE enrollment.payment_status AS ENUM ('pending', 'partial', 'paid', 'overdue');

CREATE TYPE enrollment.completion_status AS ENUM ('ongoing', 'completed', 'dropped');

CREATE TYPE enrollment.enrollment_source AS ENUM ('b2b', 'b2c');

CREATE TYPE enrollment.discount_type AS ENUM (
  'fixed_amount', 'percentage', 'fixed_final_price'
);

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

-- TABLES ------------------------------------------------------

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
  partner_id        UUID                          NULL,   -- FK to partnerships.partners (deferred)
  franchisee_id     UUID                          NULL,   -- FK to partnerships.franchisees (deferred)
  price             NUMERIC(12,2)                 NOT NULL DEFAULT 0.00,
  final_price       NUMERIC(12,2)                 NOT NULL DEFAULT 0.00,
  voucher_id        UUID                          NULL REFERENCES enrollment.vouchers(id) ON DELETE SET NULL,
  credit_applied    NUMERIC(12,2)                 NOT NULL DEFAULT 0.00,
  student_credit_id UUID                          NULL,   -- FK to finance.student_credits (deferred)
  payment_status    enrollment.payment_status     NOT NULL DEFAULT 'pending',
  completion_status enrollment.completion_status  NOT NULL DEFAULT 'ongoing',
  source            enrollment.enrollment_source  NOT NULL,
  created_at        TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  CONSTRAINT uq_enrollment UNIQUE (student_id, course_batch_id)
);

SELECT attach_updated_at_trigger('enrollment','enrollments');

CREATE INDEX idx_enrollments_student   ON enrollment.enrollments(student_id);
CREATE INDEX idx_enrollments_batch     ON enrollment.enrollments(course_batch_id);
CREATE INDEX idx_enrollments_partner   ON enrollment.enrollments(partner_id) WHERE partner_id IS NOT NULL;
CREATE INDEX idx_enrollments_status    ON enrollment.enrollments(payment_status, completion_status);

CREATE TABLE enrollment.voucher_usages (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  voucher_id     UUID        NOT NULL REFERENCES enrollment.vouchers(id) ON DELETE RESTRICT,
  enrollment_id  UUID        NOT NULL UNIQUE REFERENCES enrollment.enrollments(id) ON DELETE RESTRICT,
  original_price NUMERIC(12,2) NOT NULL,
  final_price    NUMERIC(12,2) NOT NULL,
  used_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by     UUID        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_voucher_usages_voucher ON enrollment.voucher_usages(voucher_id);

CREATE TABLE enrollment.calendar_events (
  id                      UUID                              PRIMARY KEY DEFAULT gen_random_uuid(),
  title                   TEXT                              NOT NULL,
  description             TEXT                              NULL,
  event_type              enrollment.calendar_event_type    NOT NULL,
  start_at                TIMESTAMPTZ                       NOT NULL,
  end_at                  TIMESTAMPTZ                       NOT NULL,
  is_all_day              BOOLEAN                           NOT NULL DEFAULT FALSE,
  recurrence_rule         TEXT                              NULL,
  location                TEXT                              NULL,
  source_domain           enrollment.calendar_source_domain NULL,
  source_id               UUID                              NULL,
  partnership_agreement_id UUID                             NULL,  -- FK to partnerships (deferred)
  agenda                  TEXT                              NULL,
  meeting_notes           TEXT                              NULL,
  created_by              UUID                              NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at              TIMESTAMPTZ                       NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ                       NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('enrollment','calendar_events');

CREATE INDEX idx_cal_events_type      ON enrollment.calendar_events(event_type);
CREATE INDEX idx_cal_events_start     ON enrollment.calendar_events(start_at);
CREATE INDEX idx_cal_events_source    ON enrollment.calendar_events(source_domain, source_id)
  WHERE source_domain IS NOT NULL;

CREATE TABLE enrollment.calendar_attendees (
  id          UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    UUID                      NOT NULL REFERENCES enrollment.calendar_events(id) ON DELETE CASCADE,
  user_id     UUID                      NOT NULL REFERENCES identity.users(id) ON DELETE CASCADE,
  role        enrollment.attendee_role  NOT NULL DEFAULT 'attendee',
  rsvp_status enrollment.rsvp_status   NOT NULL DEFAULT 'pending',
  created_at  TIMESTAMPTZ               NOT NULL DEFAULT now(),
  CONSTRAINT uq_attendee_event UNIQUE (event_id, user_id)
);

CREATE INDEX idx_cal_attendees_user  ON enrollment.calendar_attendees(user_id);

CREATE TABLE enrollment.calendar_syncs (
  id               UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID                        NOT NULL UNIQUE REFERENCES identity.users(id) ON DELETE CASCADE,
  provider         enrollment.calendar_provider NOT NULL DEFAULT 'google_calendar',
  access_token     TEXT                        NOT NULL,  -- encrypted at rest
  refresh_token    TEXT                        NOT NULL,  -- encrypted at rest
  last_synced_at   TIMESTAMPTZ                 NULL,
  token_expires_at TIMESTAMPTZ                 NULL,
  created_at       TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ                 NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('enrollment','calendar_syncs');

-- ============================================================
-- SCHEMA: finance
-- payments, payment_terms, payment_transactions, refunds,
-- student_credits, invoices, invoice_line_items,
-- batch_cost_line_items, extra_revenues, period_bonuses,
-- budget_template_items (alias), batch_budget_items,
-- budget_realizations
-- ============================================================
CREATE SCHEMA IF NOT EXISTS finance;

-- ENUMS -------------------------------------------------------
CREATE TYPE finance.payment_type AS ENUM ('full', 'installment');

CREATE TYPE finance.payment_status AS ENUM ('pending', 'partial', 'paid', 'overdue');

CREATE TYPE finance.term_status AS ENUM ('unpaid', 'paid', 'overdue');

CREATE TYPE finance.transaction_method AS ENUM ('gateway', 'bank_transfer');

CREATE TYPE finance.transaction_status AS ENUM ('pending', 'confirmed', 'failed', 'cancelled');

CREATE TYPE finance.refund_type AS ENUM ('full', 'partial', 'no_refund', 'credit');

CREATE TYPE finance.refund_status AS ENUM ('pending', 'completed');

CREATE TYPE finance.invoice_billed_to AS ENUM ('partner', 'student');

CREATE TYPE finance.invoice_status AS ENUM ('draft', 'sent', 'paid', 'overdue', 'cancelled');

CREATE TYPE finance.cost_ref_type AS ENUM ('manual', 'facilitator_fee', 'partner_split', 'other');

CREATE TYPE finance.extra_revenue_approval AS ENUM ('pending', 'approved', 'rejected');

CREATE TYPE finance.period_type AS ENUM ('monthly');

CREATE TYPE finance.period_bonus_status AS ENUM ('draft', 'finalized');

CREATE TYPE finance.royalty_status AS ENUM ('unpaid', 'overdue', 'paid');

-- TABLES ------------------------------------------------------

CREATE TABLE finance.payments (
  id            UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id UUID                   NOT NULL UNIQUE REFERENCES enrollment.enrollments(id) ON DELETE RESTRICT,
  payment_type  finance.payment_type   NOT NULL DEFAULT 'full',
  total_amount  NUMERIC(12,2)          NOT NULL DEFAULT 0.00,
  paid_amount   NUMERIC(12,2)          NOT NULL DEFAULT 0.00,
  status        finance.payment_status NOT NULL DEFAULT 'pending',
  created_at    TIMESTAMPTZ            NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ            NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('finance','payments');

CREATE INDEX idx_payments_status ON finance.payments(status);

CREATE TABLE finance.payment_terms (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id  UUID                NOT NULL REFERENCES finance.payments(id) ON DELETE CASCADE,
  term_number INTEGER             NOT NULL,
  due_date    DATE                NOT NULL,
  amount      NUMERIC(12,2)       NOT NULL DEFAULT 0.00,
  status      finance.term_status NOT NULL DEFAULT 'unpaid',
  created_at  TIMESTAMPTZ         NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ         NOT NULL DEFAULT now(),
  CONSTRAINT uq_payment_term UNIQUE (payment_id, term_number)
);

SELECT attach_updated_at_trigger('finance','payment_terms');

CREATE INDEX idx_payment_terms_payment   ON finance.payment_terms(payment_id);
CREATE INDEX idx_payment_terms_due_date  ON finance.payment_terms(due_date) WHERE status = 'unpaid';

CREATE TABLE finance.payment_transactions (
  id              UUID                          PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_term_id UUID                          NOT NULL REFERENCES finance.payment_terms(id) ON DELETE RESTRICT,
  method          finance.transaction_method    NOT NULL,
  amount          NUMERIC(12,2)                 NOT NULL DEFAULT 0.00,
  status          finance.transaction_status    NOT NULL DEFAULT 'pending',
  gateway_ref     TEXT                          NULL,
  proof_url       TEXT                          NULL,
  confirmed_by    UUID                          NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  confirmed_at    TIMESTAMPTZ                   NULL,
  created_at      TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ                   NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('finance','payment_transactions');

CREATE INDEX idx_transactions_term   ON finance.payment_transactions(payment_term_id);
CREATE INDEX idx_transactions_status ON finance.payment_transactions(status);

CREATE TABLE finance.student_credits (
  id               UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       UUID           NOT NULL REFERENCES identity.students(id) ON DELETE RESTRICT,
  amount           NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  source_refund_id UUID           NULL,   -- FK to finance.refunds (deferred — circular, added below)
  used_amount      NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  remaining_amount NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  expires_at       DATE           NULL,
  created_at       TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ    NOT NULL DEFAULT now(),
  CONSTRAINT chk_credit_amounts CHECK (
    used_amount >= 0 AND remaining_amount >= 0 AND
    used_amount <= amount AND remaining_amount = amount - used_amount
  )
);

SELECT attach_updated_at_trigger('finance','student_credits');

CREATE INDEX idx_student_credits_student ON finance.student_credits(student_id);

-- Wire deferred FK on enrollments.student_credit_id
ALTER TABLE enrollment.enrollments
  ADD CONSTRAINT fk_enrollment_student_credit
  FOREIGN KEY (student_credit_id) REFERENCES finance.student_credits(id) ON DELETE SET NULL;

CREATE TABLE finance.refunds (
  id             UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id  UUID                   NOT NULL REFERENCES enrollment.enrollments(id) ON DELETE RESTRICT,
  payment_id     UUID                   NOT NULL REFERENCES finance.payments(id) ON DELETE RESTRICT,
  refund_type    finance.refund_type    NOT NULL,
  refund_amount  NUMERIC(12,2)          NULL,
  credit_amount  NUMERIC(12,2)          NULL,
  reason         TEXT                   NOT NULL,
  processed_by   UUID                   NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  processed_at   TIMESTAMPTZ            NOT NULL,
  status         finance.refund_status  NOT NULL DEFAULT 'pending',
  created_at     TIMESTAMPTZ            NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ            NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('finance','refunds');

CREATE INDEX idx_refunds_enrollment ON finance.refunds(enrollment_id);

-- Wire deferred FK on student_credits.source_refund_id
ALTER TABLE finance.student_credits
  ADD CONSTRAINT fk_credit_refund
  FOREIGN KEY (source_refund_id) REFERENCES finance.refunds(id) ON DELETE SET NULL;

CREATE TABLE finance.invoices (
  id              UUID                       PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number  TEXT                       NOT NULL UNIQUE,
  enrollment_id   UUID                       NOT NULL REFERENCES enrollment.enrollments(id) ON DELETE RESTRICT,
  payment_id      UUID                       NOT NULL REFERENCES finance.payments(id) ON DELETE RESTRICT,
  billed_to       finance.invoice_billed_to  NOT NULL,
  partner_id      UUID                       NULL,   -- FK to partnerships.partners (deferred)
  student_id      UUID                       NULL REFERENCES identity.students(id) ON DELETE RESTRICT,
  status          finance.invoice_status     NOT NULL DEFAULT 'draft',
  issued_date     DATE                       NOT NULL,
  due_date        DATE                       NULL,
  subtotal        NUMERIC(12,2)              NOT NULL DEFAULT 0.00,
  discount_amount NUMERIC(12,2)              NOT NULL DEFAULT 0.00,
  total_amount    NUMERIC(12,2)              NOT NULL DEFAULT 0.00,
  notes           TEXT                       NULL,
  created_by      UUID                       NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at      TIMESTAMPTZ                NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ                NOT NULL DEFAULT now(),
  CONSTRAINT chk_invoice_billed_partner CHECK (
    billed_to <> 'partner' OR partner_id IS NOT NULL
  ),
  CONSTRAINT chk_invoice_billed_student CHECK (
    billed_to <> 'student' OR student_id IS NOT NULL
  )
);

SELECT attach_updated_at_trigger('finance','invoices');

-- Partial unique: one non-cancelled invoice per enrollment
CREATE UNIQUE INDEX uq_invoice_enrollment_active
  ON finance.invoices(enrollment_id)
  WHERE status <> 'cancelled';

CREATE INDEX idx_invoices_partner ON finance.invoices(partner_id) WHERE partner_id IS NOT NULL;
CREATE INDEX idx_invoices_student ON finance.invoices(student_id) WHERE student_id IS NOT NULL;
CREATE INDEX idx_invoices_status  ON finance.invoices(status);

CREATE TABLE finance.invoice_line_items (
  id         UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID           NOT NULL REFERENCES finance.invoices(id) ON DELETE CASCADE,
  label      TEXT           NOT NULL,
  amount     NUMERIC(12,2)  NOT NULL,
  sort_order INTEGER        NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE INDEX idx_line_items_invoice ON finance.invoice_line_items(invoice_id);

CREATE TABLE finance.batch_cost_line_items (
  id               UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id  UUID                    NOT NULL REFERENCES catalog.course_batches(id) ON DELETE CASCADE,
  template_ref_id  UUID                    NULL REFERENCES catalog.course_cost_templates(id) ON DELETE SET NULL,
  label            TEXT                    NOT NULL,
  amount           NUMERIC(12,2)           NOT NULL DEFAULT 0.00,
  cost_type        catalog.cost_type       NOT NULL DEFAULT 'fixed',
  is_removed       BOOLEAN                 NOT NULL DEFAULT FALSE,
  reference_type   finance.cost_ref_type   NOT NULL DEFAULT 'manual',
  reference_id     UUID                    NULL,
  created_by       UUID                    NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at       TIMESTAMPTZ             NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ             NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('finance','batch_cost_line_items');

CREATE INDEX idx_batch_costs_batch     ON finance.batch_cost_line_items(course_batch_id);
CREATE INDEX idx_batch_costs_ref       ON finance.batch_cost_line_items(reference_type, reference_id)
  WHERE reference_id IS NOT NULL;

CREATE TABLE finance.extra_revenues (
  id               UUID                          PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id  UUID                          NOT NULL REFERENCES catalog.course_batches(id) ON DELETE RESTRICT,
  label            TEXT                          NOT NULL,
  amount           NUMERIC(12,2)                 NOT NULL DEFAULT 0.00,
  added_by         UUID                          NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  approval_status  finance.extra_revenue_approval NOT NULL DEFAULT 'pending',
  approved_by      UUID                          NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  approved_at      TIMESTAMPTZ                   NULL,
  created_at       TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ                   NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('finance','extra_revenues');

CREATE INDEX idx_extra_revenues_batch  ON finance.extra_revenues(course_batch_id);

CREATE TABLE finance.period_bonuses (
  id                    UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  period                TEXT                        NOT NULL,  -- YYYY-MM
  period_type           finance.period_type         NOT NULL DEFAULT 'monthly',
  vernonedu_amount      NUMERIC(12,2)               NOT NULL DEFAULT 0.00,
  course_creator_amount NUMERIC(12,2)               NOT NULL DEFAULT 0.00,
  dept_leader_amount    NUMERIC(12,2)               NOT NULL DEFAULT 0.00,
  batch_refs            UUID[]                      NOT NULL DEFAULT '{}',
  calculated_at         TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  calculated_by         UUID                        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  status                finance.period_bonus_status NOT NULL DEFAULT 'draft',
  created_at            TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ                 NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('finance','period_bonuses');

CREATE UNIQUE INDEX uq_period_bonus ON finance.period_bonuses(period, period_type);

CREATE TABLE finance.batch_budget_items (
  id               UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id  UUID           NOT NULL REFERENCES catalog.course_batches(id) ON DELETE CASCADE,
  template_ref_id  UUID           NULL REFERENCES catalog.course_budget_template_items(id) ON DELETE SET NULL,
  label            TEXT           NOT NULL,
  category         TEXT           NULL,
  planned_amount   NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  overridable      BOOLEAN        NOT NULL DEFAULT TRUE,
  class_id         UUID           NULL REFERENCES catalog.classes(id) ON DELETE SET NULL,
  created_by       UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at       TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ    NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('finance','batch_budget_items');

CREATE INDEX idx_budget_items_batch ON finance.batch_budget_items(course_batch_id);
CREATE INDEX idx_budget_items_class ON finance.batch_budget_items(class_id) WHERE class_id IS NOT NULL;

CREATE TABLE finance.budget_realizations (
  id                  UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_budget_item_id UUID          NOT NULL REFERENCES finance.batch_budget_items(id) ON DELETE CASCADE,
  class_id            UUID           NULL REFERENCES catalog.classes(id) ON DELETE SET NULL,
  actual_amount       NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  description         TEXT           NOT NULL,
  spent_at            DATE           NOT NULL,
  proof_url           TEXT           NULL,
  recorded_by         UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at          TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ    NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('finance','budget_realizations');

CREATE INDEX idx_realizations_item  ON finance.budget_realizations(batch_budget_item_id);

-- ============================================================
-- SCHEMA: credentialing
-- certificate_types, certificate_configs, student_certificates,
-- certificate_action_requests
-- ============================================================
CREATE SCHEMA IF NOT EXISTS credentialing;

-- Certificate number sequences — one per year (pattern)
CREATE SEQUENCE IF NOT EXISTS credentialing.cert_number_seq_2025 START 1;
CREATE SEQUENCE IF NOT EXISTS credentialing.cert_number_seq_2026 START 1;
CREATE SEQUENCE IF NOT EXISTS credentialing.cert_number_seq_2027 START 1;

-- ENUMS -------------------------------------------------------
CREATE TYPE credentialing.cert_category AS ENUM (
  'vernonedu_competence', 'vernonedu_participation', 'partner'
);

CREATE TYPE credentialing.issued_on AS ENUM ('completion', 'manual');

CREATE TYPE credentialing.cert_status AS ENUM ('pending', 'issued', 'revoked');

CREATE TYPE credentialing.cert_action AS ENUM ('revoke', 'reissue');

CREATE TYPE credentialing.action_status AS ENUM ('pending', 'approved', 'rejected');

-- TABLES ------------------------------------------------------

CREATE TABLE credentialing.certificate_types (
  id               UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT                      NOT NULL,
  category         credentialing.cert_category NOT NULL,
  validity_months  INTEGER                   NULL CHECK (validity_months > 0),
  is_active        BOOLEAN                   NOT NULL DEFAULT TRUE,
  created_by       UUID                      NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at       TIMESTAMPTZ               NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ               NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('credentialing','certificate_types');

CREATE TABLE credentialing.certificate_configs (
  id                  UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id           UUID                     NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  certificate_type_id UUID                     NOT NULL REFERENCES credentialing.certificate_types(id) ON DELETE RESTRICT,
  issued_on           credentialing.issued_on  NOT NULL DEFAULT 'completion',
  created_at          TIMESTAMPTZ              NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ              NOT NULL DEFAULT now(),
  CONSTRAINT uq_cert_config UNIQUE (course_id, certificate_type_id)
);

SELECT attach_updated_at_trigger('credentialing','certificate_configs');

CREATE INDEX idx_cert_configs_course ON credentialing.certificate_configs(course_id);

CREATE TABLE credentialing.student_certificates (
  id                   UUID                       PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id        UUID                       NOT NULL REFERENCES enrollment.enrollments(id) ON DELETE RESTRICT,
  certificate_type_id  UUID                       NOT NULL REFERENCES credentialing.certificate_types(id) ON DELETE RESTRICT,
  certificate_config_id UUID                      NOT NULL REFERENCES credentialing.certificate_configs(id) ON DELETE RESTRICT,
  certificate_number   TEXT                       NOT NULL UNIQUE,
  issued_at            TIMESTAMPTZ                NOT NULL DEFAULT now(),
  status               credentialing.cert_status  NOT NULL DEFAULT 'pending',
  qr_code_url          TEXT                       NULL,
  expires_at           DATE                       NULL,
  revoked_at           TIMESTAMPTZ                NULL,
  revoked_by           UUID                       NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  reissued_from        UUID                       NULL REFERENCES credentialing.student_certificates(id) ON DELETE SET NULL,
  created_at           TIMESTAMPTZ                NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ                NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('credentialing','student_certificates');

CREATE INDEX idx_student_certs_enrollment ON credentialing.student_certificates(enrollment_id);
CREATE INDEX idx_student_certs_number     ON credentialing.student_certificates(certificate_number);
CREATE INDEX idx_student_certs_status     ON credentialing.student_certificates(status);
CREATE INDEX idx_student_certs_expires    ON credentialing.student_certificates(expires_at)
  WHERE expires_at IS NOT NULL;

CREATE TABLE credentialing.certificate_action_requests (
  id                     UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_certificate_id UUID                        NOT NULL REFERENCES credentialing.student_certificates(id) ON DELETE RESTRICT,
  action                 credentialing.cert_action   NOT NULL,
  reason                 TEXT                        NOT NULL,
  requested_by           UUID                        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  approved_by            UUID                        NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  status                 credentialing.action_status NOT NULL DEFAULT 'pending',
  created_at             TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  resolved_at            TIMESTAMPTZ                 NULL
);

SELECT attach_updated_at_trigger('credentialing','certificate_action_requests');

CREATE INDEX idx_cert_actions_cert   ON credentialing.certificate_action_requests(student_certificate_id);
CREATE INDEX idx_cert_actions_status ON credentialing.certificate_action_requests(status);

-- ============================================================
-- SCHEMA: partnerships
-- partners, partnership_agreements, partner_documents,
-- franchisees, franchise_agreements, branch_other_revenues,
-- royalty_payment_records
-- ============================================================
CREATE SCHEMA IF NOT EXISTS partnerships;

-- ENUMS -------------------------------------------------------
CREATE TYPE partnerships.partner_type AS ENUM (
  'university', 'vendor', 'sponsor', 'franchise_candidate', 'community', 'other'
);

CREATE TYPE partnerships.partner_status AS ENUM ('lead', 'active', 'inactive');

CREATE TYPE partnerships.agreement_status AS ENUM (
  'draft', 'active', 'expired', 'terminated'
);

CREATE TYPE partnerships.payment_model AS ENUM (
  'per_visit', 'per_course', 'per_student'
);

CREATE TYPE partnerships.agreement_payer AS ENUM ('partner', 'student');

CREATE TYPE partnerships.document_type AS ENUM (
  'mou', 'proposal', 'addendum', 'termination_letter', 'other'
);

CREATE TYPE partnerships.franchisee_status AS ENUM ('active', 'inactive', 'terminated');

CREATE TYPE partnerships.franchise_agreement_status AS ENUM (
  'active', 'inactive', 'terminated'
);

-- TABLES ------------------------------------------------------

CREATE TABLE partnerships.partners (
  id            UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT                      NOT NULL,
  type          partnerships.partner_type NOT NULL,
  status        partnerships.partner_status NOT NULL DEFAULT 'lead',
  contact_name  TEXT                      NULL,
  contact_email TEXT                      NULL,
  contact_phone TEXT                      NULL,
  address       TEXT                      NULL,
  notes         TEXT                      NULL,
  deleted_at    TIMESTAMPTZ               NULL,
  created_at    TIMESTAMPTZ               NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ               NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('partnerships','partners');

CREATE INDEX idx_partners_status ON partnerships.partners(status);
CREATE INDEX idx_partners_type   ON partnerships.partners(type);

-- Wire deferred FKs to partners
ALTER TABLE identity.students
  ADD CONSTRAINT fk_student_partner
  FOREIGN KEY (partner_id) REFERENCES partnerships.partners(id) ON DELETE SET NULL;

ALTER TABLE enrollment.enrollments
  ADD CONSTRAINT fk_enrollment_partner
  FOREIGN KEY (partner_id) REFERENCES partnerships.partners(id) ON DELETE RESTRICT;

ALTER TABLE finance.invoices
  ADD CONSTRAINT fk_invoice_partner
  FOREIGN KEY (partner_id) REFERENCES partnerships.partners(id) ON DELETE RESTRICT;

-- calendar_events.partnership_agreement_id FK is wired AFTER partnership_agreements table is created (see below)

CREATE TABLE partnerships.partnership_agreements (
  id                  UUID                           PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id          UUID                           NOT NULL REFERENCES partnerships.partners(id) ON DELETE RESTRICT,
  title               TEXT                           NOT NULL,
  status              partnerships.agreement_status  NOT NULL DEFAULT 'draft',
  start_date          DATE                           NOT NULL,
  end_date            DATE                           NULL,
  payment_model       partnerships.payment_model     NULL,
  payer               partnerships.agreement_payer   NULL,
  bulk_price          NUMERIC(12,2)                  NULL,
  signed_at           DATE                           NULL,
  terminated_at       DATE                           NULL,
  termination_reason  TEXT                           NULL,
  created_by          UUID                           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at          TIMESTAMPTZ                    NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ                    NOT NULL DEFAULT now(),
  CONSTRAINT chk_termination_reason CHECK (
    status <> 'terminated' OR termination_reason IS NOT NULL
  )
);

SELECT attach_updated_at_trigger('partnerships','partnership_agreements');

-- Partial unique: only one active agreement per partner
CREATE UNIQUE INDEX uq_active_agreement_per_partner
  ON partnerships.partnership_agreements(partner_id)
  WHERE status = 'active';

CREATE INDEX idx_agreements_partner ON partnerships.partnership_agreements(partner_id);
CREATE INDEX idx_agreements_status  ON partnerships.partnership_agreements(status);

-- Wire deferred FK: calendar_events.partnership_agreement_id (table now exists)
ALTER TABLE enrollment.calendar_events
  ADD CONSTRAINT fk_calendar_event_agreement
  FOREIGN KEY (partnership_agreement_id)
  REFERENCES partnerships.partnership_agreements(id)
  ON DELETE SET NULL;

CREATE TABLE partnerships.partner_documents (
  id           UUID                       PRIMARY KEY DEFAULT gen_random_uuid(),
  agreement_id UUID                       NOT NULL REFERENCES partnerships.partnership_agreements(id) ON DELETE CASCADE,
  type         partnerships.document_type NOT NULL,
  title        TEXT                       NOT NULL,
  file_url     TEXT                       NOT NULL,
  uploaded_by  UUID                       NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  uploaded_at  TIMESTAMPTZ                NOT NULL DEFAULT now()
);

CREATE INDEX idx_partner_docs_agreement ON partnerships.partner_documents(agreement_id);

CREATE TABLE partnerships.franchisees (
  id          UUID                          PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT                          NOT NULL,
  branch_name TEXT                          NOT NULL,
  location    TEXT                          NOT NULL,
  contact     TEXT                          NOT NULL,
  status      partnerships.franchisee_status NOT NULL DEFAULT 'active',
  created_by  UUID                          NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at  TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ                   NULL
);

SELECT attach_updated_at_trigger('partnerships','franchisees');

-- Wire deferred FK: enrollments.franchisee_id
ALTER TABLE enrollment.enrollments
  ADD CONSTRAINT fk_enrollment_franchisee
  FOREIGN KEY (franchisee_id) REFERENCES partnerships.franchisees(id) ON DELETE SET NULL;

CREATE TABLE partnerships.franchise_agreements (
  id                  UUID                                    PRIMARY KEY DEFAULT gen_random_uuid(),
  franchisee_id       UUID                                    NOT NULL REFERENCES partnerships.franchisees(id) ON DELETE RESTRICT,
  buy_in_fee          NUMERIC(12,2)                           NOT NULL DEFAULT 0.00,
  monthly_royalty     NUMERIC(12,2)                           NOT NULL DEFAULT 0.00,
  revenue_royalty_pct NUMERIC(5,2)                            NOT NULL DEFAULT 0.00
    CHECK (revenue_royalty_pct >= 0 AND revenue_royalty_pct <= 100),
  start_date          DATE                                    NOT NULL,
  end_date            DATE                                    NULL,
  status              partnerships.franchise_agreement_status NOT NULL DEFAULT 'active',
  created_at          TIMESTAMPTZ                             NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ                             NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('partnerships','franchise_agreements');

CREATE INDEX idx_franchise_agreements_franchisee ON partnerships.franchise_agreements(franchisee_id);

CREATE TABLE partnerships.branch_other_revenues (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  franchisee_id UUID        NOT NULL REFERENCES partnerships.franchisees(id) ON DELETE RESTRICT,
  label         TEXT        NOT NULL,
  amount        NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  revenue_date  DATE        NOT NULL,
  added_by      UUID        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_branch_revenue_franchisee ON partnerships.branch_other_revenues(franchisee_id);
CREATE INDEX idx_branch_revenue_date       ON partnerships.branch_other_revenues(revenue_date);

CREATE TABLE partnerships.royalty_payment_records (
  id                    UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  franchise_agreement_id UUID                     NOT NULL REFERENCES partnerships.franchise_agreements(id) ON DELETE RESTRICT,
  period                TEXT                      NOT NULL,  -- YYYY-MM
  gross_revenue         NUMERIC(12,2)             NOT NULL DEFAULT 0.00,
  monthly_royalty       NUMERIC(12,2)             NOT NULL DEFAULT 0.00,
  revenue_royalty       NUMERIC(12,2)             NOT NULL DEFAULT 0.00,
  total_royalty         NUMERIC(12,2)             NOT NULL DEFAULT 0.00,
  status                partnerships.royalty_status NOT NULL DEFAULT 'unpaid',
  paid_at               TIMESTAMPTZ               NULL,
  recorded_by           UUID                      NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at            TIMESTAMPTZ               NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ               NOT NULL DEFAULT now(),
  CONSTRAINT uq_royalty_period UNIQUE (franchise_agreement_id, period)
);

SELECT attach_updated_at_trigger('partnerships','royalty_payment_records');

CREATE INDEX idx_royalty_status ON partnerships.royalty_payment_records(status);

-- ============================================================
-- SCHEMA: platform
-- notification_templates, notifications, notification_preferences
-- ============================================================
CREATE SCHEMA IF NOT EXISTS platform;

-- ENUMS -------------------------------------------------------
CREATE TYPE platform.notification_channel AS ENUM ('email', 'in_app', 'push');

CREATE TYPE platform.notification_status AS ENUM ('pending', 'sent', 'failed', 'read');

CREATE TYPE platform.notification_source_domain AS ENUM (
  'payment', 'enrollment', 'team_member', 'calendar', 'partner', 'manual'
);

-- TABLES ------------------------------------------------------

CREATE TABLE platform.notification_templates (
  id        UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  key       TEXT                        NOT NULL,
  channel   platform.notification_channel NOT NULL,
  subject   TEXT                        NULL,
  body      TEXT                        NOT NULL,
  is_active BOOLEAN                     NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ                NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ                NOT NULL DEFAULT now(),
  CONSTRAINT uq_template_key_channel UNIQUE (key, channel)
);

SELECT attach_updated_at_trigger('platform','notification_templates');

CREATE INDEX idx_notif_templates_key ON platform.notification_templates(key);

CREATE TABLE platform.notifications (
  id            UUID                              PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  UUID                              NOT NULL REFERENCES identity.users(id) ON DELETE CASCADE,
  template_id   UUID                              NOT NULL REFERENCES platform.notification_templates(id) ON DELETE RESTRICT,
  channel       platform.notification_channel     NOT NULL,
  variables     JSONB                             NOT NULL DEFAULT '{}',
  status        platform.notification_status      NOT NULL DEFAULT 'pending',
  source_domain platform.notification_source_domain NULL,
  source_id     UUID                              NULL,
  scheduled_at  TIMESTAMPTZ                       NULL,
  sent_at       TIMESTAMPTZ                       NULL,
  read_at       TIMESTAMPTZ                       NULL,
  retry_count   INTEGER                           NOT NULL DEFAULT 0,
  error_message TEXT                              NULL,
  created_at    TIMESTAMPTZ                       NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ                       NOT NULL DEFAULT now()
);

SELECT attach_updated_at_trigger('platform','notifications');

CREATE INDEX idx_notifications_recipient ON platform.notifications(recipient_id);
CREATE INDEX idx_notifications_status    ON platform.notifications(status);
CREATE INDEX idx_notifications_scheduled ON platform.notifications(scheduled_at)
  WHERE scheduled_at IS NOT NULL AND status = 'pending';
CREATE INDEX idx_notifications_source    ON platform.notifications(source_domain, source_id)
  WHERE source_domain IS NOT NULL;

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

-- ============================================================
-- END OF MIGRATION
-- ============================================================
