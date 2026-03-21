CREATE TABLE IF NOT EXISTS accounting_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference_number VARCHAR(50) UNIQUE,
    description TEXT NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('income','expense','transfer')),
    amount NUMERIC(15,2) NOT NULL,
    debit_account_code VARCHAR(20),
    credit_account_code VARCHAR(20),
    category VARCHAR(100),
    related_entity_type VARCHAR(50),
    related_entity_id UUID,
    transaction_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'completed' CHECK (status IN ('draft','completed','cancelled')),
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_accounting_transactions_date ON accounting_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_accounting_transactions_type ON accounting_transactions(transaction_type);
