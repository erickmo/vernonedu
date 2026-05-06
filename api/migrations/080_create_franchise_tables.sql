-- 080_create_franchise_tables.sql

CREATE TABLE franchisees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    branch_name VARCHAR(255) NOT NULL,
    location TEXT NOT NULL DEFAULT '',
    contact VARCHAR(255) NOT NULL DEFAULT '',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_franchisees_status ON franchisees(status);
CREATE INDEX idx_franchisees_created_at ON franchisees(created_at DESC);

CREATE TABLE franchise_agreements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    franchisee_id UUID NOT NULL REFERENCES franchisees(id),
    buy_in_fee NUMERIC(15,2) NOT NULL DEFAULT 0,
    monthly_royalty NUMERIC(15,2) NOT NULL DEFAULT 0,
    revenue_royalty_pct NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (revenue_royalty_pct >= 0 AND revenue_royalty_pct <= 100),
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_franchise_agreements_franchisee ON franchise_agreements(franchisee_id);

CREATE TABLE royalty_payment_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    franchise_agreement_id UUID NOT NULL REFERENCES franchise_agreements(id),
    period VARCHAR(7) NOT NULL,
    gross_revenue NUMERIC(15,2) NOT NULL DEFAULT 0,
    monthly_royalty NUMERIC(15,2) NOT NULL DEFAULT 0,
    revenue_royalty NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_royalty NUMERIC(15,2) NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'unpaid',
    paid_at TIMESTAMPTZ,
    recorded_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(franchise_agreement_id, period)
);

CREATE INDEX idx_royalty_payment_records_agreement ON royalty_payment_records(franchise_agreement_id);
CREATE INDEX idx_royalty_payment_records_period ON royalty_payment_records(period);
CREATE INDEX idx_royalty_payment_records_status ON royalty_payment_records(status);

CREATE TABLE branch_other_revenues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    franchisee_id UUID NOT NULL REFERENCES franchisees(id),
    label VARCHAR(255) NOT NULL,
    amount NUMERIC(15,2) NOT NULL DEFAULT 0,
    revenue_date DATE NOT NULL,
    added_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_branch_other_revenues_franchisee ON branch_other_revenues(franchisee_id);
CREATE INDEX idx_branch_other_revenues_date ON branch_other_revenues(revenue_date DESC);
