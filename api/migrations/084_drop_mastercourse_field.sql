-- Migration 084: Remove field column from master_courses
-- Field (bidang studi) removed from product — no longer required or collected.

ALTER TABLE master_courses ALTER COLUMN field DROP NOT NULL;
ALTER TABLE master_courses ALTER COLUMN field SET DEFAULT '';

DROP INDEX IF EXISTS idx_master_courses_field;
