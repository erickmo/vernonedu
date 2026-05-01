-- ============================================================
-- Migration 000010: team_member schema
-- Replaces deprecated facilitator tables in identity schema.
-- Facilitators are a specialization (is_facilitator = true).
-- ============================================================

CREATE SCHEMA IF NOT EXISTS team_member;

-- Enums (scoped to team_member schema)
CREATE TYPE team_member.employment_status AS ENUM ('active', 'inactive', 'on_leave');
CREATE TYPE team_member.review_status     AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE team_member.fee_basis         AS ENUM ('per_class', 'per_course', 'both');

-- Core member table
CREATE TABLE team_member.team_members (
  id                UUID                           PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID                           NOT NULL UNIQUE REFERENCES identity.users(id) ON DELETE CASCADE,
  full_name         TEXT                           NOT NULL,
  phone             TEXT                           NOT NULL,
  department_id     UUID                           NULL REFERENCES identity.departments(id) ON DELETE SET NULL,
  employment_status team_member.employment_status  NOT NULL DEFAULT 'active',
  joined_at         DATE                           NOT NULL,
  is_facilitator    BOOLEAN                        NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ                    NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ                    NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('team_member', 'team_members');
CREATE INDEX idx_tm_user_id    ON team_member.team_members(user_id);
CREATE INDEX idx_tm_department ON team_member.team_members(department_id) WHERE department_id IS NOT NULL;
CREATE INDEX idx_tm_facilitator ON team_member.team_members(is_facilitator) WHERE is_facilitator = TRUE;

-- Facilitator profile (exists only when is_facilitator = true)
CREATE TABLE team_member.facilitator_profiles (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  team_member_id UUID        NOT NULL UNIQUE REFERENCES team_member.team_members(id) ON DELETE CASCADE,
  specialization TEXT        NOT NULL,
  bio            TEXT        NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('team_member', 'facilitator_profiles');

-- Fee tiers (created by vernonedu_admin)
CREATE TABLE team_member.fee_tiers (
  id                UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  name              TEXT           NOT NULL,
  amount_per_class  NUMERIC(12,2)  NULL,
  amount_per_course NUMERIC(12,2)  NULL,
  is_active         BOOLEAN        NOT NULL DEFAULT TRUE,
  created_by        UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at        TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ    NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('team_member', 'fee_tiers');

-- Facilitator proposals (two-stage approval flow)
CREATE TABLE team_member.facilitator_proposals (
  id                          UUID                         PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id                   UUID                         NOT NULL,
  proposed_by                 UUID                         NOT NULL REFERENCES team_member.team_members(id) ON DELETE RESTRICT,
  facilitator_id              UUID                         NOT NULL REFERENCES team_member.team_members(id) ON DELETE RESTRICT,
  fee_tier_id                 UUID                         NOT NULL REFERENCES team_member.fee_tiers(id) ON DELETE RESTRICT,
  fee_basis                   team_member.fee_basis        NOT NULL,
  dept_leader_status          team_member.review_status    NOT NULL DEFAULT 'pending',
  dept_leader_reviewed_at     TIMESTAMPTZ                  NULL,
  dept_leader_note            TEXT                         NULL,
  academic_leader_status      team_member.review_status    NOT NULL DEFAULT 'pending',
  academic_leader_reviewed_at TIMESTAMPTZ                  NULL,
  academic_leader_note        TEXT                         NULL,
  final_status                team_member.review_status    NOT NULL DEFAULT 'pending',
  created_at                  TIMESTAMPTZ                  NOT NULL DEFAULT now(),
  updated_at                  TIMESTAMPTZ                  NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('team_member', 'facilitator_proposals');
CREATE INDEX idx_fp_course        ON team_member.facilitator_proposals(course_id);
CREATE INDEX idx_fp_facilitator   ON team_member.facilitator_proposals(facilitator_id);
CREATE INDEX idx_fp_final_status  ON team_member.facilitator_proposals(final_status);
CREATE INDEX idx_fp_proposed_by   ON team_member.facilitator_proposals(proposed_by);
