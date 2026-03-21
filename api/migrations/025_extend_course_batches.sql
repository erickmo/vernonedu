-- Migration 025: Extend course_batches with additional fields
-- Adds: code (unique batch identifier), min_participants, website_visible, price, payment_method

ALTER TABLE course_batches
    ADD COLUMN IF NOT EXISTS code             VARCHAR(50)    DEFAULT '',
    ADD COLUMN IF NOT EXISTS min_participants  INT            DEFAULT 0,
    ADD COLUMN IF NOT EXISTS website_visible   BOOLEAN        DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS price             BIGINT         DEFAULT 0,
    ADD COLUMN IF NOT EXISTS payment_method    VARCHAR(20)    DEFAULT 'upfront';

ALTER TABLE course_batches
    ADD CONSTRAINT chk_course_batches_payment_method
        CHECK (payment_method IN ('upfront', 'scheduled', 'monthly', 'batch_lump', 'per_session'));

CREATE UNIQUE INDEX IF NOT EXISTS idx_course_batches_code
    ON course_batches(code) WHERE code != '' AND code IS NOT NULL;

-- Backfill code for existing batches
UPDATE course_batches
SET code = 'BATCH-' || TO_CHAR(created_at, 'YYYY') || '-' || LPAD(CAST(ROW_NUMBER() OVER (ORDER BY created_at) AS TEXT), 4, '0')
WHERE code = '' OR code IS NULL;
