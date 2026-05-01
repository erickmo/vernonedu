DROP TRIGGER IF EXISTS set_updated_at ON budget.realizations;
ALTER TABLE budget.realizations DROP COLUMN IF EXISTS updated_at;

ALTER TABLE budget.batch_items
    DROP CONSTRAINT IF EXISTS batch_items_template_ref_id_fkey,
    ADD CONSTRAINT batch_items_template_ref_id_fkey
        FOREIGN KEY (template_ref_id)
        REFERENCES budget.template_items(id);
