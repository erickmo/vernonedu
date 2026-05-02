-- Business Model Canvas (9 strategic blocks per branch)
CREATE TABLE IF NOT EXISTS business_model_canvases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL UNIQUE REFERENCES branches(id) ON DELETE CASCADE,
    customer_segments JSONB NOT NULL DEFAULT '[]'::jsonb,
    value_propositions JSONB NOT NULL DEFAULT '[]'::jsonb,
    channels JSONB NOT NULL DEFAULT '[]'::jsonb,
    customer_relationships JSONB NOT NULL DEFAULT '[]'::jsonb,
    revenue_streams JSONB NOT NULL DEFAULT '[]'::jsonb,
    key_resources JSONB NOT NULL DEFAULT '[]'::jsonb,
    key_activities JSONB NOT NULL DEFAULT '[]'::jsonb,
    key_partnerships JSONB NOT NULL DEFAULT '[]'::jsonb,
    cost_structure JSONB NOT NULL DEFAULT '[]'::jsonb,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bmc_branch_id ON business_model_canvases(branch_id);
