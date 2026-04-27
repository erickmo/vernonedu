-- ============================================================
-- Migration 000012: franchise schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS franchise;

CREATE TYPE franchise.franchisee_status AS ENUM ('active', 'inactive', 'terminated');
CREATE TYPE franchise.agreement_status   AS ENUM ('active', 'inactive', 'terminated');
CREATE TYPE franchise.royalty_status     AS ENUM ('unpaid', 'overdue', 'paid');

-- Franchisees: investor/location owners.
-- VernonEdu retains 100% operational management.
CREATE TABLE franchise.franchisees (
  id          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT                        NOT NULL,
  branch_name TEXT                        NOT NULL,
  location    TEXT                        NOT NULL,
  contact     TEXT                        NOT NULL,
  status      franchise.franchisee_status NOT NULL DEFAULT 'active',
  created_by  UUID                        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at  TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ                 NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('franchise','franchisees');
CREATE INDEX idx_franchisees_status ON franchise.franchisees(status);

-- Franchise agreements: financial terms per franchisee.
CREATE TABLE franchise.franchise_agreements (
  id                  UUID                      PRIMARY KEY DEFAULT gen_random_uuid(),
  franchisee_id       UUID                      NOT NULL REFERENCES franchise.franchisees(id) ON DELETE RESTRICT,
  buy_in_fee          NUMERIC(14,2)             NOT NULL DEFAULT 0.00,
  monthly_royalty     NUMERIC(14,2)             NOT NULL DEFAULT 0.00,
  revenue_royalty_pct NUMERIC(5,2)              NOT NULL DEFAULT 0.00
                        CONSTRAINT chk_revenue_royalty_pct CHECK (revenue_royalty_pct BETWEEN 0 AND 100),
  start_date          DATE                      NOT NULL,
  end_date            DATE                      NULL,
  status              franchise.agreement_status NOT NULL DEFAULT 'active',
  created_at          TIMESTAMPTZ               NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ               NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('franchise','franchise_agreements');
CREATE INDEX idx_franchise_agreements_franchisee ON franchise.franchise_agreements(franchisee_id);

-- Non-enrollment revenue entries for a branch (e.g. event fees, space rental).
CREATE TABLE franchise.branch_other_revenues (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  franchisee_id UUID          NOT NULL REFERENCES franchise.franchisees(id) ON DELETE RESTRICT,
  label         TEXT          NOT NULL,
  amount        NUMERIC(14,2) NOT NULL DEFAULT 0.00,
  revenue_date  DATE          NOT NULL,
  added_by      UUID          NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('franchise','branch_other_revenues');
CREATE INDEX idx_branch_revenues_franchisee ON franchise.branch_other_revenues(franchisee_id);
CREATE INDEX idx_branch_revenues_date       ON franchise.branch_other_revenues(revenue_date);

-- Monthly royalty payment records.
-- gross_revenue   = enrollment_fees + other_revenues for the period.
-- revenue_royalty = gross_revenue * revenue_royalty_pct / 100.
-- total_royalty   = monthly_royalty + revenue_royalty.
CREATE TABLE franchise.royalty_payment_records (
  id                    UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
  franchise_agreement_id UUID                  NOT NULL REFERENCES franchise.franchise_agreements(id) ON DELETE RESTRICT,
  period                TEXT                   NOT NULL,  -- YYYY-MM
  gross_revenue         NUMERIC(14,2)          NOT NULL DEFAULT 0.00,
  monthly_royalty       NUMERIC(14,2)          NOT NULL DEFAULT 0.00,
  revenue_royalty       NUMERIC(14,2)          NOT NULL DEFAULT 0.00,
  total_royalty         NUMERIC(14,2)          NOT NULL DEFAULT 0.00,
  status                franchise.royalty_status NOT NULL DEFAULT 'unpaid',
  created_at            TIMESTAMPTZ            NOT NULL DEFAULT now(),
  paid_at               TIMESTAMPTZ            NULL,
  recorded_by           UUID                   NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  CONSTRAINT uq_royalty_period UNIQUE (franchise_agreement_id, period)
);
CREATE INDEX idx_royalty_records_agreement ON franchise.royalty_payment_records(franchise_agreement_id);
CREATE INDEX idx_royalty_records_status    ON franchise.royalty_payment_records(status) WHERE status = 'unpaid';
