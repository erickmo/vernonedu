CREATE TABLE IF NOT EXISTS okr_objectives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    owner_id UUID,
    owner_name TEXT NOT NULL DEFAULT '',
    period TEXT NOT NULL DEFAULT '',
    level TEXT NOT NULL DEFAULT 'company',
    status TEXT NOT NULL DEFAULT 'on_track',
    progress INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS okr_key_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    objective_id UUID NOT NULL REFERENCES okr_objectives(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    progress INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
