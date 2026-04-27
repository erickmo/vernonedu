DROP INDEX IF EXISTS finance.idx_invoices_provider_ref;

ALTER TABLE finance.invoices
  DROP COLUMN IF EXISTS paid_at,
  DROP COLUMN IF EXISTS provider_ref,
  DROP COLUMN IF EXISTS payment_provider;
