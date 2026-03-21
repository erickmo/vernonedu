CREATE TABLE IF NOT EXISTS finance_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('asset','liability','equity','revenue','expense')),
    parent_id UUID REFERENCES finance_accounts(id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    branch_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_finance_accounts_code ON finance_accounts(code);
CREATE INDEX IF NOT EXISTS idx_finance_accounts_branch ON finance_accounts(branch_id);

CREATE TABLE IF NOT EXISTS finance_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    account_debit_id UUID NOT NULL REFERENCES finance_accounts(id),
    account_credit_id UUID NOT NULL REFERENCES finance_accounts(id),
    amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    reference VARCHAR(100),
    branch_id UUID NOT NULL,
    source VARCHAR(20) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','auto')),
    attachment_url TEXT,
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_finance_transactions_branch ON finance_transactions(branch_id);
CREATE INDEX IF NOT EXISTS idx_finance_transactions_source ON finance_transactions(source);
CREATE INDEX IF NOT EXISTS idx_finance_transactions_created_at ON finance_transactions(created_at);

CREATE TABLE IF NOT EXISTS journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES finance_transactions(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES finance_accounts(id),
    debit NUMERIC(15,2) NOT NULL DEFAULT 0,
    credit NUMERIC(15,2) NOT NULL DEFAULT 0,
    description TEXT NOT NULL,
    source VARCHAR(30) NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','auto_invoice','auto_payable','auto_commission')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_journal_entries_transaction ON journal_entries(transaction_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_account ON journal_entries(account_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_source ON journal_entries(source);
CREATE INDEX IF NOT EXISTS idx_journal_entries_created_at ON journal_entries(created_at);
