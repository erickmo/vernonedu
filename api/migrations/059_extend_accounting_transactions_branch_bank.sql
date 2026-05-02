ALTER TABLE accounting_transactions
    ADD COLUMN IF NOT EXISTS branch_id UUID,
    ADD COLUMN IF NOT EXISTS bank_account_id UUID REFERENCES bank_accounts(id);
CREATE INDEX IF NOT EXISTS idx_accounting_transactions_branch ON accounting_transactions(branch_id);
CREATE INDEX IF NOT EXISTS idx_accounting_transactions_bank_account ON accounting_transactions(bank_account_id);
