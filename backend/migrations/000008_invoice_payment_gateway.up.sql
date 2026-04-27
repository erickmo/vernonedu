-- ============================================================
-- Migration 000008: payment gateway columns on invoices
-- Adds provider tracking + paid timestamp for external gateways
-- (e.g. Midtrans Snap). Nullable so existing rows remain valid.
-- ============================================================

ALTER TABLE finance.invoices
  ADD COLUMN IF NOT EXISTS payment_provider TEXT        NULL,
  ADD COLUMN IF NOT EXISTS provider_ref     TEXT        NULL,
  ADD COLUMN IF NOT EXISTS paid_at          TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_invoices_provider_ref
  ON finance.invoices(provider_ref)
  WHERE provider_ref IS NOT NULL;
