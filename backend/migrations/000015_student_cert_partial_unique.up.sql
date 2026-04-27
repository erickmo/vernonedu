-- ============================================================
-- Migration 000015: replace (enrollment, config) UNIQUE with partial unique
-- ============================================================
-- Reissue creates a second row for the same (enrollment_id, certificate_config_id)
-- where the original is revoked and the new one is issued. The strict UNIQUE
-- constraint introduced in 000014 blocks this.
--
-- We replace it with a partial UNIQUE INDEX that only enforces uniqueness for
-- non-revoked rows, allowing at most one ACTIVE certificate per
-- (enrollment, config) pair while permitting historical revoked rows.

ALTER TABLE credentialing.student_certificates
  DROP CONSTRAINT IF EXISTS uq_student_cert_enrollment_config;

CREATE UNIQUE INDEX IF NOT EXISTS uq_student_cert_active
  ON credentialing.student_certificates (enrollment_id, certificate_config_id)
  WHERE status <> 'revoked';
