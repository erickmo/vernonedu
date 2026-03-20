-- Drop old items table and recreate for canvas use
DROP TABLE IF EXISTS items;
CREATE TABLE items (
    id UUID PRIMARY KEY,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    canvas_type VARCHAR(50) NOT NULL,
    section_id VARCHAR(100) NOT NULL,
    text TEXT NOT NULL DEFAULT '',
    note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_items_business_canvas ON items(business_id, canvas_type);
CREATE INDEX IF NOT EXISTS idx_items_section ON items(business_id, canvas_type, section_id);
