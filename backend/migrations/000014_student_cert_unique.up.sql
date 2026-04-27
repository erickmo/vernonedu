-- ============================================================
-- Migration 000014: unique (enrollment_id, certificate_config_id) on student_certificates
-- ============================================================
-- Prevents issuing the same (enrollment, certificate_config) pair twice.
-- Service layer maps 23505 on this constraint to apperrors.ErrConflict.

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_student_cert_enrollment_config'
  ) THEN
    ALTER TABLE credentialing.student_certificates
      ADD CONSTRAINT uq_student_cert_enrollment_config
      UNIQUE (enrollment_id, certificate_config_id);
  END IF;
END $$;
