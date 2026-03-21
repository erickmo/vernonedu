CREATE TABLE facilitator_levels (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level         INT  NOT NULL,
    name          TEXT NOT NULL,
    fee_per_session BIGINT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (level)
);

CREATE INDEX idx_facilitator_levels_level ON facilitator_levels(level);
