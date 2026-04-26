-- ============================================================
-- Migration 000005: credentialing schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS credentialing;

CREATE SEQUENCE IF NOT EXISTS credentialing.cert_number_seq_2025 START 1;
CREATE SEQUENCE IF NOT EXISTS credentialing.cert_number_seq_2026 START 1;
CREATE SEQUENCE IF NOT EXISTS credentialing.cert_number_seq_2027 START 1;

CREATE TYPE credentialing.cert_category AS ENUM (
  'vernonedu_competence', 'vernonedu_participation', 'partner'
);
CREATE TYPE credentialing.issued_on AS ENUM ('completion', 'manual');
CREATE TYPE credentialing.cert_status AS ENUM ('pending', 'issued', 'revoked');
CREATE TYPE credentialing.cert_action AS ENUM ('revoke', 'reissue');
CREATE TYPE credentialing.action_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TABLE credentialing.certificate_types (
  id              UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT                        NOT NULL,
  category        credentialing.cert_category NOT NULL,
  validity_months INTEGER                     NULL CHECK (validity_months > 0),
  is_active       BOOLEAN                     NOT NULL DEFAULT TRUE,
  created_by      UUID                        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at      TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ                 NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('credentialing','certificate_types');

CREATE TABLE credentialing.certificate_configs (
  id                  UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id           UUID                    NOT NULL REFERENCES catalog.courses(id) ON DELETE CASCADE,
  certificate_type_id UUID                    NOT NULL REFERENCES credentialing.certificate_types(id) ON DELETE RESTRICT,
  issued_on           credentialing.issued_on NOT NULL DEFAULT 'completion',
  created_at          TIMESTAMPTZ             NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ             NOT NULL DEFAULT now(),
  CONSTRAINT uq_cert_config UNIQUE (course_id, certificate_type_id)
);
SELECT attach_updated_at_trigger('credentialing','certificate_configs');
CREATE INDEX idx_cert_configs_course ON credentialing.certificate_configs(course_id);

CREATE TABLE credentialing.student_certificates (
  id                    UUID                       PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id         UUID                       NOT NULL REFERENCES enrollment.enrollments(id) ON DELETE RESTRICT,
  certificate_type_id   UUID                       NOT NULL REFERENCES credentialing.certificate_types(id) ON DELETE RESTRICT,
  certificate_config_id UUID                       NOT NULL REFERENCES credentialing.certificate_configs(id) ON DELETE RESTRICT,
  certificate_number    TEXT                       NOT NULL UNIQUE,
  issued_at             TIMESTAMPTZ                NOT NULL DEFAULT now(),
  status                credentialing.cert_status  NOT NULL DEFAULT 'pending',
  qr_code_url           TEXT                       NULL,
  expires_at            DATE                       NULL,
  revoked_at            TIMESTAMPTZ                NULL,
  revoked_by            UUID                       NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  reissued_from         UUID                       NULL REFERENCES credentialing.student_certificates(id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ                NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ                NOT NULL DEFAULT now()
);
SELECT attach_updated_at_trigger('credentialing','student_certificates');
CREATE INDEX idx_student_certs_enrollment ON credentialing.student_certificates(enrollment_id);
CREATE INDEX idx_student_certs_number     ON credentialing.student_certificates(certificate_number);
CREATE INDEX idx_student_certs_status     ON credentialing.student_certificates(status);
CREATE INDEX idx_student_certs_expires    ON credentialing.student_certificates(expires_at) WHERE expires_at IS NOT NULL;

CREATE TABLE credentialing.certificate_action_requests (
  id                     UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_certificate_id UUID                        NOT NULL REFERENCES credentialing.student_certificates(id) ON DELETE RESTRICT,
  action                 credentialing.cert_action   NOT NULL,
  reason                 TEXT                        NOT NULL,
  requested_by           UUID                        NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  approved_by            UUID                        NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  status                 credentialing.action_status NOT NULL DEFAULT 'pending',
  created_at             TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ                 NOT NULL DEFAULT now(),
  resolved_at            TIMESTAMPTZ                 NULL
);
SELECT attach_updated_at_trigger('credentialing','certificate_action_requests');
CREATE INDEX idx_cert_actions_cert   ON credentialing.certificate_action_requests(student_certificate_id);
CREATE INDEX idx_cert_actions_status ON credentialing.certificate_action_requests(status);
