-- ============================================================
-- Migration 000006: partnerships schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS partnerships;

CREATE TYPE partnerships.partner_type AS ENUM (
  'university', 'vendor', 'sponsor', 'franchise_candidate', 'community', 'other'
);
CREATE TYPE partnerships.partner_status AS ENUM ('lead', 'active', 'inactive');
CREATE TYPE partnerships.agreement_status AS ENUM ('draft', 'active', 'expired', 'terminated');
CREATE TYPE partnerships.payment_model AS ENUM ('per_visit', 'per_course', 'per_student');
CREATE TYPE partnerships.agreement_payer AS ENUM ('partner', 'student');
CREATE TYPE partnerships.document_type AS ENUM ('mou', 'proposal', 'addendum', 'termination_letter', 'other');
CREATE TYPE partnerships.franchisee_status AS ENUM ('active', 'inactive', 'terminated');
CREATE TYPE partnerships.franchise_agreement_status AS ENUM ('active', 'inactive', 'terminated');
CREATE TYPE partnerships.royalty_status AS ENUM ('unpaid', 'paid', 'overdue');

CREATE TABLE partnerships.partners (
  id            UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT                        NOT NULL,
  type          partnerships.partner_type   NOT NULL,
  status        partnerships.partner_status NOT NULL DEFAULT 'lead',
  contact_name  TEXT                        NULL,
  contact_email TEXT                        NULL,
  contact_phone TEXT                        NULL,
  address       TEXT                        NULL,
  notes         TEXT                        NULL,
  deleted_at    TIMESTAMPTZ                 NULL,
  created_at    TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ                 NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('partnerships','partners');
CREATE INDEX idx_partners_status ON partnerships.partners(status);
CREATE INDEX idx_partners_type   ON partnerships.partners(type);

ALTER TABLE identity.students
  ADD CONSTRAINT fk_student_partner
  FOREIGN KEY (partner_id) REFERENCES partnerships.partners(id) ON DELETE SET NULL;

ALTER TABLE enrollment.enrollments
  ADD CONSTRAINT fk_enrollment_partner
  FOREIGN KEY (partner_id) REFERENCES partnerships.partners(id) ON DELETE RESTRICT;

ALTER TABLE finance.invoices
  ADD CONSTRAINT fk_invoice_partner
  FOREIGN KEY (partner_id) REFERENCES partnerships.partners(id) ON DELETE RESTRICT;

CREATE TABLE partnerships.partnership_agreements (
  id                 UUID                           PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id         UUID                           NOT NULL REFERENCES partnerships.partners(id) ON DELETE RESTRICT,
  title              TEXT                           NOT NULL,
  status             partnerships.agreement_status  NOT NULL DEFAULT 'draft',
  start_date         DATE                           NOT NULL,
  end_date           DATE                           NULL,
  payment_model      partnerships.payment_model     NULL,
  payer              partnerships.agreement_payer   NULL,
  bulk_price         NUMERIC(12,2)                  NULL,
  signed_at          DATE                           NULL,
  terminated_at      DATE                           NULL,
  termination_reason TEXT                           NULL,
  created_by         UUID                           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at         TIMESTAMPTZ                    NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ                    NOT NULL DEFAULT now(),
  CONSTRAINT chk_termination_reason CHECK (status <> 'terminated' OR termination_reason IS NOT NULL)
);
SELECT attach_updated_at_trigger('partnerships','partnership_agreements');
CREATE UNIQUE INDEX uq_active_agreement_per_partner ON partnerships.partnership_agreements(partner_id) WHERE status = 'active';
CREATE INDEX idx_agreements_partner ON partnerships.partnership_agreements(partner_id);
CREATE INDEX idx_agreements_status  ON partnerships.partnership_agreements(status);

ALTER TABLE enrollment.calendar_events
  ADD CONSTRAINT fk_calendar_event_agreement
  FOREIGN KEY (partnership_agreement_id) REFERENCES partnerships.partnership_agreements(id) ON DELETE SET NULL;

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
  id          UUID                           PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT                           NOT NULL,
  branch_name TEXT                           NOT NULL,
  location    TEXT                           NOT NULL,
  contact     TEXT                           NOT NULL,
  status      partnerships.franchisee_status NOT NULL DEFAULT 'active',
  created_by  UUID                           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at  TIMESTAMPTZ                    NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ                    NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ                    NULL
);
SELECT attach_updated_at_trigger('partnerships','franchisees');

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
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  franchisee_id UUID          NOT NULL REFERENCES partnerships.franchisees(id) ON DELETE RESTRICT,
  label         TEXT          NOT NULL,
  amount        NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  revenue_date  DATE          NOT NULL,
  added_by      UUID          NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX idx_branch_revenue_franchisee ON partnerships.branch_other_revenues(franchisee_id);
CREATE INDEX idx_branch_revenue_date       ON partnerships.branch_other_revenues(revenue_date);

CREATE TABLE partnerships.royalty_payment_records (
  id                     UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  franchise_agreement_id UUID                        NOT NULL REFERENCES partnerships.franchise_agreements(id) ON DELETE RESTRICT,
  period                 TEXT                        NOT NULL,
  gross_revenue          NUMERIC(12,2)               NOT NULL DEFAULT 0.00,
  monthly_royalty        NUMERIC(12,2)               NOT NULL DEFAULT 0.00,
  revenue_royalty        NUMERIC(12,2)               NOT NULL DEFAULT 0.00,
  total_royalty          NUMERIC(12,2)               NOT NULL DEFAULT 0.00,
  status                 partnerships.royalty_status NOT NULL DEFAULT 'unpaid',
  paid_at                TIMESTAMPTZ                 NULL,
  recorded_by            UUID                        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at             TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  CONSTRAINT uq_royalty_period UNIQUE (franchise_agreement_id, period)
);
SELECT attach_updated_at_trigger('partnerships','royalty_payment_records');
CREATE INDEX idx_royalty_status ON partnerships.royalty_payment_records(status);
