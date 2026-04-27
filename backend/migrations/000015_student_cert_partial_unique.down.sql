DROP INDEX IF EXISTS credentialing.uq_student_cert_active;

ALTER TABLE credentialing.student_certificates
  ADD CONSTRAINT uq_student_cert_enrollment_config
  UNIQUE (enrollment_id, certificate_config_id);
