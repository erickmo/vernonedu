CREATE TABLE IF NOT EXISTS catalog.student_module_access (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID NOT NULL,
  module_id   UUID NOT NULL REFERENCES catalog.modules(id) ON DELETE CASCADE,
  granted_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (student_id, module_id)
);
CREATE INDEX IF NOT EXISTS idx_sma_student ON catalog.student_module_access(student_id);
