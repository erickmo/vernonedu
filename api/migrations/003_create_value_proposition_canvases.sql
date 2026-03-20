-- Create value_proposition_canvases table
CREATE TABLE IF NOT EXISTS value_proposition_canvases (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_canvases_name ON value_proposition_canvases(name);
