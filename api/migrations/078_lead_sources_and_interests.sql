-- 078_lead_sources_and_interests.sql

-- Lead sources entity table
CREATE TABLE lead_sources (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT        NOT NULL,
    is_active  BOOLEAN     NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default sources (mirrors old enum)
INSERT INTO lead_sources (name) VALUES
    ('Referral'),
    ('Media Sosial'),
    ('Walk In'),
    ('Website'),
    ('Lainnya');

-- Lead interests: multi-link to course entities
CREATE TABLE lead_interests (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id     UUID        NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    entity_type TEXT        NOT NULL CHECK (entity_type IN ('master_course', 'course_type', 'course_batch')),
    entity_id   UUID        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lead_interests_lead_id ON lead_interests(lead_id);

-- Update leads table: drop old string columns, add FK
ALTER TABLE leads DROP COLUMN IF EXISTS interest;
ALTER TABLE leads DROP COLUMN IF EXISTS source;
ALTER TABLE leads ADD COLUMN source_id UUID REFERENCES lead_sources(id) ON DELETE SET NULL;
