-- ============================================================
-- Migration 000001: identity schema
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

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

CREATE SCHEMA IF NOT EXISTS identity;

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

CREATE TABLE identity.users (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email             TEXT        NOT NULL UNIQUE,
  password_hash     TEXT        NOT NULL,
  role              identity.user_role NOT NULL,
  is_active         BOOLEAN     NOT NULL DEFAULT TRUE,
  device_push_token TEXT        NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('identity','users');
CREATE INDEX idx_users_role  ON identity.users(role);
CREATE INDEX idx_users_email ON identity.users(email);

CREATE TABLE identity.students (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL UNIQUE REFERENCES identity.users(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  email      TEXT        NOT NULL,
  phone      TEXT        NOT NULL,
  source     identity.student_source NOT NULL DEFAULT 'b2c',
  partner_id UUID        NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('identity','students');
CREATE INDEX idx_students_user_id    ON identity.students(user_id);
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
  id                UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  name              TEXT           NOT NULL,
  amount_per_class  NUMERIC(12,2)  NULL,
  amount_per_course NUMERIC(12,2)  NULL,
  created_by        UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  is_active         BOOLEAN        NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ    NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('identity','fee_tiers');

CREATE TABLE identity.facilitator_proposals (
  id                          UUID                              PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id                   UUID                              NOT NULL,
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
CREATE INDEX idx_proposals_course       ON identity.facilitator_proposals(course_id);
CREATE INDEX idx_proposals_facilitator  ON identity.facilitator_proposals(facilitator_id);
CREATE INDEX idx_proposals_final_status ON identity.facilitator_proposals(final_status);
