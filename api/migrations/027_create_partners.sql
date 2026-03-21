CREATE TABLE IF NOT EXISTS partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    industry TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    contact_person TEXT NOT NULL DEFAULT '',
    contact_email TEXT NOT NULL DEFAULT '',
    contact_phone TEXT NOT NULL DEFAULT '',
    website TEXT NOT NULL DEFAULT '',
    logo_url TEXT NOT NULL DEFAULT '',
    group_id UUID REFERENCES partner_groups(id) ON DELETE SET NULL,
    group_name TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'prospect',
    partner_since DATE,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
