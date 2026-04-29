DROP INDEX IF EXISTS catalog.idx_courses_code;
ALTER TABLE catalog.courses
  DROP COLUMN IF EXISTS status,
  DROP COLUMN IF EXISTS format,
  DROP COLUMN IF EXISTS duration_days,
  DROP COLUMN IF EXISTS description,
  DROP COLUMN IF EXISTS code;
