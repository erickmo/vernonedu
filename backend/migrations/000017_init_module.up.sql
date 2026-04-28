CREATE TYPE catalog.coverage_status AS ENUM ('planned', 'covered');

CREATE TABLE catalog.class_module_coverages (
  id              UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id        UUID                    NOT NULL REFERENCES catalog.classes(id) ON DELETE CASCADE,
  module_id       UUID                    NOT NULL REFERENCES catalog.modules(id) ON DELETE CASCADE,
  status          catalog.coverage_status NOT NULL DEFAULT 'planned',
  covered_by      UUID                    NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  covered_at      TIMESTAMPTZ             NULL,
  is_auto_covered BOOLEAN                 NOT NULL DEFAULT FALSE,
  notes           TEXT                    NULL,
  created_by      UUID                    NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at      TIMESTAMPTZ             NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ             NOT NULL DEFAULT now(),
  CONSTRAINT uq_class_module UNIQUE (class_id, module_id)
);
SELECT attach_updated_at_trigger('catalog', 'class_module_coverages');
CREATE INDEX idx_class_module_coverages_class  ON catalog.class_module_coverages(class_id);
CREATE INDEX idx_class_module_coverages_module ON catalog.class_module_coverages(module_id);
