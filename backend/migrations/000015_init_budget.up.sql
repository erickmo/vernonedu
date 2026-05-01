CREATE SCHEMA IF NOT EXISTS budget;

CREATE TABLE budget.template_items (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id      UUID NOT NULL,
  label          TEXT NOT NULL,
  category       TEXT NULL,
  preset_amount  NUMERIC(15,2) NOT NULL DEFAULT 0,
  overridable    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_budget_tmpl_course ON budget.template_items(course_id);

CREATE TABLE budget.batch_items (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_batch_id  UUID NOT NULL,
  template_ref_id  UUID NULL REFERENCES budget.template_items(id),
  label            TEXT NOT NULL,
  category         TEXT NULL,
  planned_amount   NUMERIC(15,2) NOT NULL DEFAULT 0,
  overridable      BOOLEAN NOT NULL DEFAULT TRUE,
  class_id         UUID NULL,
  created_by       UUID NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_budget_batch_items_batch ON budget.batch_items(course_batch_id);
CREATE INDEX idx_budget_batch_items_class ON budget.batch_items(class_id) WHERE class_id IS NOT NULL;

CREATE TABLE budget.realizations (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_budget_item_id UUID NOT NULL REFERENCES budget.batch_items(id) ON DELETE CASCADE,
  class_id             UUID NULL,
  actual_amount        NUMERIC(15,2) NOT NULL DEFAULT 0,
  description          TEXT NOT NULL,
  spent_at             DATE NOT NULL,
  proof_url            TEXT NULL,
  recorded_by          UUID NOT NULL,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_budget_realizations_item ON budget.realizations(batch_budget_item_id);

SELECT attach_updated_at_trigger('budget', 'template_items');
SELECT attach_updated_at_trigger('budget', 'batch_items');
