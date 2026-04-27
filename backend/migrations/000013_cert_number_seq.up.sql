-- ============================================================
-- Migration 000013: per-year certificate number sequence table
-- ============================================================

CREATE TABLE IF NOT EXISTS credentialing.certificate_number_sequences (
  year       INTEGER PRIMARY KEY,
  last_value INTEGER NOT NULL DEFAULT 0
);
