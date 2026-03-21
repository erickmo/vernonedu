CREATE TABLE IF NOT EXISTS payables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL,
    recipient_id UUID NOT NULL,
    recipient_name VARCHAR(255) NOT NULL,
    batch_id UUID REFERENCES course_batches(id) ON DELETE SET NULL,
    amount BIGINT NOT NULL DEFAULT 0,
    calculation_basis VARCHAR(20),
    calculation_percentage FLOAT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    source VARCHAR(10) NOT NULL DEFAULT 'manual',
    paid_at TIMESTAMPTZ,
    payment_proof TEXT,
    branch_id UUID,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payables_status ON payables(status);
CREATE INDEX IF NOT EXISTS idx_payables_type ON payables(type);
CREATE INDEX IF NOT EXISTS idx_payables_batch ON payables(batch_id);
CREATE INDEX IF NOT EXISTS idx_payables_recipient ON payables(recipient_id);
CREATE INDEX IF NOT EXISTS idx_payables_created ON payables(created_at);
