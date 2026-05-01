-- Fix 1: ON DELETE SET NULL for template_ref_id
ALTER TABLE budget.batch_items
    DROP CONSTRAINT IF EXISTS batch_items_template_ref_id_fkey,
    ADD CONSTRAINT batch_items_template_ref_id_fkey
        FOREIGN KEY (template_ref_id)
        REFERENCES budget.template_items(id)
        ON DELETE SET NULL;

-- Fix 2: Add updated_at to realizations
ALTER TABLE budget.realizations
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

SELECT attach_updated_at_trigger('budget', 'realizations');
