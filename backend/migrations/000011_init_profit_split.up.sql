-- ============================================================
-- Migration 000011: profit_split schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS profit_split;

CREATE TYPE profit_split.approval_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE profit_split.cost_type AS ENUM ('fixed', 'percentage_of_revenue');
CREATE TYPE profit_split.cost_ref_type AS ENUM ('manual', 'facilitator_fee', 'partner_split', 'template', 'other');
CREATE TYPE profit_split.period_type AS ENUM ('monthly');
CREATE TYPE profit_split.period_bonus_status AS ENUM ('draft', 'finalized');

-- Singleton global split settings (one row, upserted).
CREATE TABLE profit_split.global_settings (
  id                   UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  vernonedu_pct        NUMERIC(6,4)   NOT NULL,
  course_creator_pct   NUMERIC(6,4)   NOT NULL,
  dept_leader_pct      NUMERIC(6,4)   NOT NULL,
  updated_by           UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  updated_at           TIMESTAMPTZ    NOT NULL DEFAULT now(),
  CONSTRAINT chk_global_pct_sum CHECK (
    vernonedu_pct + course_creator_pct + dept_leader_pct = 100
  )
);

-- CEO per-course override.
CREATE TABLE profit_split.course_overrides (
  id                   UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id            UUID           NOT NULL UNIQUE REFERENCES catalog.courses(id) ON DELETE CASCADE,
  vernonedu_pct        NUMERIC(6,4)   NOT NULL,
  course_creator_pct   NUMERIC(6,4)   NOT NULL,
  dept_leader_pct      NUMERIC(6,4)   NOT NULL,
  overridden_by        UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  overridden_at        TIMESTAMPTZ    NOT NULL DEFAULT now(),
  created_at           TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ    NOT NULL DEFAULT now(),
  CONSTRAINT chk_override_pct_sum CHECK (
    vernonedu_pct + course_creator_pct + dept_leader_pct = 100
  )
);
SELECT attach_updated_at_trigger('profit_split','course_overrides');
CREATE INDEX idx_co_course ON profit_split.course_overrides(course_id);

-- Extra revenue added by finance, approved by CEO.
CREATE TABLE profit_split.extra_revenues (
  id               UUID                           PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id  UUID                           NOT NULL REFERENCES catalog.course_batches(id) ON DELETE RESTRICT,
  label            TEXT                           NOT NULL,
  amount           NUMERIC(12,2)                  NOT NULL DEFAULT 0.00,
  added_by         UUID                           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  approval_status  profit_split.approval_status   NOT NULL DEFAULT 'pending',
  approved_by      UUID                           NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  approved_at      TIMESTAMPTZ                    NULL,
  created_at       TIMESTAMPTZ                    NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ                    NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('profit_split','extra_revenues');
CREATE INDEX idx_er_batch ON profit_split.extra_revenues(course_batch_id);

-- Batch cost line items.
CREATE TABLE profit_split.batch_cost_line_items (
  id               UUID                          PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id  UUID                          NOT NULL REFERENCES catalog.course_batches(id) ON DELETE CASCADE,
  template_ref     UUID                          NULL,
  label            TEXT                          NOT NULL,
  amount           NUMERIC(12,2)                 NOT NULL DEFAULT 0.00,
  cost_type        profit_split.cost_type        NOT NULL DEFAULT 'fixed',
  is_removed       BOOLEAN                       NOT NULL DEFAULT FALSE,
  reference_type   profit_split.cost_ref_type    NOT NULL DEFAULT 'manual',
  reference_id     UUID                          NULL,
  created_by       UUID                          NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at       TIMESTAMPTZ                   NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ                   NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('profit_split','batch_cost_line_items');
CREATE INDEX idx_bcli_batch ON profit_split.batch_cost_line_items(course_batch_id);

-- Calculated split record per closed batch.
CREATE TABLE profit_split.batch_split_records (
  id                    UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id       UUID           NOT NULL UNIQUE REFERENCES catalog.course_batches(id) ON DELETE RESTRICT,
  gross_revenue         NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  total_costs           NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  net_profit            NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  vernonedu_pct         NUMERIC(6,4)   NOT NULL,
  course_creator_pct    NUMERIC(6,4)   NOT NULL,
  dept_leader_pct       NUMERIC(6,4)   NOT NULL,
  vernonedu_amount      NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  course_creator_amount NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  dept_leader_amount    NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  calculated_at         TIMESTAMPTZ    NOT NULL DEFAULT now(),
  calculated_by         UUID           NULL REFERENCES identity.users(id) ON DELETE SET NULL
);
CREATE INDEX idx_bsr_batch ON profit_split.batch_split_records(course_batch_id);

-- Monthly aggregated period bonus.
CREATE TABLE profit_split.period_bonuses (
  id                    UUID                              PRIMARY KEY DEFAULT gen_random_uuid(),
  period                TEXT                              NOT NULL,
  period_type           profit_split.period_type          NOT NULL DEFAULT 'monthly',
  vernonedu_amount      NUMERIC(12,2)                     NOT NULL DEFAULT 0.00,
  course_creator_amount NUMERIC(12,2)                     NOT NULL DEFAULT 0.00,
  dept_leader_amount    NUMERIC(12,2)                     NOT NULL DEFAULT 0.00,
  batch_refs            UUID[]                            NOT NULL DEFAULT '{}',
  calculated_at         TIMESTAMPTZ                       NOT NULL DEFAULT now(),
  calculated_by         UUID                              NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  status                profit_split.period_bonus_status  NOT NULL DEFAULT 'draft',
  created_at            TIMESTAMPTZ                       NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ                       NOT NULL DEFAULT now(),
  CONSTRAINT uq_period_bonus UNIQUE (period, period_type)
);
SELECT attach_updated_at_trigger('profit_split','period_bonuses');
CREATE INDEX idx_pb_period ON profit_split.period_bonuses(period);
