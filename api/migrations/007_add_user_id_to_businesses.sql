ALTER TABLE businesses
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_businesses_user_id ON businesses(user_id);
