CREATE TABLE IF NOT EXISTS certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES certificate_templates(id),
    student_id UUID REFERENCES students(id) ON DELETE SET NULL,
    batch_id UUID REFERENCES course_batches(id) ON DELETE SET NULL,
    course_id UUID,
    type VARCHAR(30) NOT NULL CHECK (type IN ('participant','competency')),
    certificate_code VARCHAR(64) NOT NULL UNIQUE,
    qr_code_url TEXT NOT NULL DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','revoked')),
    revoked_at TIMESTAMPTZ,
    revocation_reason TEXT,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_certificates_student_id ON certificates(student_id);
CREATE INDEX IF NOT EXISTS idx_certificates_batch_id ON certificates(batch_id);
CREATE INDEX IF NOT EXISTS idx_certificates_code ON certificates(certificate_code);
CREATE INDEX IF NOT EXISTS idx_certificates_status ON certificates(status);
