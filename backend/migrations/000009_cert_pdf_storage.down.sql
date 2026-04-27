DROP INDEX IF EXISTS credentialing.uq_student_certs_enrollment_active;
DROP INDEX IF EXISTS credentialing.uq_student_certs_pdf_hash;

ALTER TABLE credentialing.student_certificates
  DROP COLUMN IF EXISTS pdf_path,
  DROP COLUMN IF EXISTS pdf_hash;
