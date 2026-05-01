-- ============================================================
-- Migration 000004: finance schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS finance;

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
  id          UUID                NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
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
CREATE INDEX idx_payment_terms_payment  ON finance.payment_terms(payment_id);
CREATE INDEX idx_payment_terms_due_date ON finance.payment_terms(due_date) WHERE status = 'unpaid';

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
  source_refund_id UUID           NULL,
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

ALTER TABLE finance.student_credits
  ADD CONSTRAINT fk_credit_refund
  FOREIGN KEY (source_refund_id) REFERENCES finance.refunds(id) ON DELETE SET NULL;

CREATE TABLE finance.invoices (
  id              UUID                       PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number  TEXT                       NOT NULL UNIQUE,
  enrollment_id   UUID                       NOT NULL REFERENCES enrollment.enrollments(id) ON DELETE RESTRICT,
  payment_id      UUID                       NOT NULL REFERENCES finance.payments(id) ON DELETE RESTRICT,
  billed_to       finance.invoice_billed_to  NOT NULL,
  partner_id      UUID                       NULL,
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
  CONSTRAINT chk_invoice_billed_partner CHECK (billed_to <> 'partner' OR partner_id IS NOT NULL),
  CONSTRAINT chk_invoice_billed_student CHECK (billed_to <> 'student' OR student_id IS NOT NULL)
);
SELECT attach_updated_at_trigger('finance','invoices');
CREATE UNIQUE INDEX uq_invoice_enrollment_active ON finance.invoices(enrollment_id) WHERE status <> 'cancelled';
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
  id               UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id  UUID                  NOT NULL REFERENCES catalog.course_batches(id) ON DELETE CASCADE,
  template_ref_id  UUID                  NULL REFERENCES catalog.course_cost_templates(id) ON DELETE SET NULL,
  label            TEXT                  NOT NULL,
  amount           NUMERIC(12,2)         NOT NULL DEFAULT 0.00,
  cost_type        catalog.cost_type     NOT NULL DEFAULT 'fixed',
  is_removed       BOOLEAN               NOT NULL DEFAULT FALSE,
  reference_type   finance.cost_ref_type NOT NULL DEFAULT 'manual',
  reference_id     UUID                  NULL,
  created_by       UUID                  NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at       TIMESTAMPTZ           NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ           NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('finance','batch_cost_line_items');
CREATE INDEX idx_batch_costs_batch ON finance.batch_cost_line_items(course_batch_id);

CREATE TABLE finance.extra_revenues (
  id               UUID                           PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id  UUID                           NOT NULL REFERENCES catalog.course_batches(id) ON DELETE RESTRICT,
  label            TEXT                           NOT NULL,
  amount           NUMERIC(12,2)                  NOT NULL DEFAULT 0.00,
  added_by         UUID                           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  approval_status  finance.extra_revenue_approval NOT NULL DEFAULT 'pending',
  approved_by      UUID                           NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  approved_at      TIMESTAMPTZ                    NULL,
  created_at       TIMESTAMPTZ                    NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ                    NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('finance','extra_revenues');
CREATE INDEX idx_extra_revenues_batch ON finance.extra_revenues(course_batch_id);

CREATE TABLE finance.period_bonuses (
  id                    UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  period                TEXT                        NOT NULL,
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
  id                   UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_budget_item_id UUID           NOT NULL REFERENCES finance.batch_budget_items(id) ON DELETE CASCADE,
  class_id             UUID           NULL REFERENCES catalog.classes(id) ON DELETE SET NULL,
  actual_amount        NUMERIC(12,2)  NOT NULL DEFAULT 0.00,
  description          TEXT           NOT NULL,
  spent_at             DATE           NOT NULL,
  proof_url            TEXT           NULL,
  recorded_by          UUID           NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at           TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ    NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('finance','budget_realizations');
CREATE INDEX idx_realizations_item ON finance.budget_realizations(batch_budget_item_id);
