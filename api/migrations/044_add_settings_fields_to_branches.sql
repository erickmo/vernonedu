ALTER TABLE branches
    ADD COLUMN IF NOT EXISTS region       TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS contact_name  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS contact_phone TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS status        VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive'));
