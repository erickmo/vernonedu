CREATE TABLE IF NOT EXISTS accounting_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number VARCHAR(50) UNIQUE,
    student_id UUID REFERENCES students(id),
    enrollment_id UUID REFERENCES enrollments(id),
    course_batch_id UUID REFERENCES course_batches(id),
    student_name VARCHAR(255),
    batch_name VARCHAR(255),
    payment_method VARCHAR(30),
    amount NUMERIC(15,2) NOT NULL,
    due_date DATE,
    paid_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','sent','paid','overdue','cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_accounting_invoices_status ON accounting_invoices(status);
CREATE INDEX IF NOT EXISTS idx_accounting_invoices_due_date ON accounting_invoices(due_date);
