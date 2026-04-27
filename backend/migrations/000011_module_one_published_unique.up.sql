-- Migration 000011: enforce at-most-one published version per module.
-- A partial unique index ensures atomic publish + auto-archive transactions
-- can never leave two 'published' rows for the same module visible.

CREATE UNIQUE INDEX IF NOT EXISTS uq_module_one_published
  ON catalog.module_versions (module_id) WHERE status = 'published';
