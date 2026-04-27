-- ============================================================
-- Migration 000008: certificate PDF storage + verification hash
-- ============================================================

ALTER TABLE credentialing.student_certificates
  ADD COLUMN IF NOT EXISTS pdf_path TEXT NULL,
  ADD COLUMN IF NOT EXISTS pdf_hash TEXT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_student_certs_pdf_hash
  ON credentialing.student_certificates(pdf_hash)
  WHERE pdf_hash IS NOT NULL;

-- Idempotency: at most one non-revoked certificate per enrollment.
CREATE UNIQUE INDEX IF NOT EXISTS uq_student_certs_enrollment_active
  ON credentialing.student_certificates(enrollment_id)
  WHERE status <> 'revoked';
