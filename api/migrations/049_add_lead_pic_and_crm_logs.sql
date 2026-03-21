ALTER TABLE leads ADD COLUMN IF NOT EXISTS pic_id UUID REFERENCES users(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS lead_crm_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    contacted_by_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    contact_method VARCHAR(50) NOT NULL DEFAULT 'phone',
    response TEXT NOT NULL DEFAULT '',
    follow_up_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lead_crm_logs_lead_id ON lead_crm_logs(lead_id);
CREATE INDEX idx_lead_crm_logs_created_at ON lead_crm_logs(created_at DESC);
CREATE INDEX idx_leads_pic_id ON leads(pic_id);
CREATE INDEX idx_leads_source ON leads(source);
