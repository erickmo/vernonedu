-- Migration: extend accounting_invoices with new columns and indexes

ALTER TABLE accounting_invoices
  ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('auto','manual')),
  ADD COLUMN IF NOT EXISTS client_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS paid_amount NUMERIC(15,2),
  ADD COLUMN IF NOT EXISTS payment_proof TEXT,
  ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES branches(id),
  ADD COLUMN IF NOT EXISTS session_id UUID,
  ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancel_reason TEXT,
  ADD COLUMN IF NOT EXISTS paid_by UUID REFERENCES users(id);

CREATE INDEX IF NOT EXISTS idx_accounting_invoices_student_id ON accounting_invoices(student_id);
CREATE INDEX IF NOT EXISTS idx_accounting_invoices_batch_id ON accounting_invoices(course_batch_id);
CREATE INDEX IF NOT EXISTS idx_accounting_invoices_status ON accounting_invoices(status);
CREATE INDEX IF NOT EXISTS idx_accounting_invoices_due_date ON accounting_invoices(due_date);
