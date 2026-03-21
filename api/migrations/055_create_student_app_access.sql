CREATE TABLE IF NOT EXISTS student_app_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL,
    app_name VARCHAR(100) NOT NULL,
    batch_id UUID NOT NULL,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','revoked'))
);
CREATE INDEX IF NOT EXISTS idx_student_app_access_student ON student_app_access(student_id);
CREATE INDEX IF NOT EXISTS idx_student_app_access_batch ON student_app_access(batch_id);
CREATE INDEX IF NOT EXISTS idx_student_app_access_status ON student_app_access(status);
