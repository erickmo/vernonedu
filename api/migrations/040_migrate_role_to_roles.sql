-- Migrate users from single role column to roles TEXT[] array
ALTER TABLE users ADD COLUMN IF NOT EXISTS roles TEXT[] NOT NULL DEFAULT '{}';

-- Copy existing role value into the new roles array
UPDATE users SET roles = ARRAY[role] WHERE role IS NOT NULL AND role != '';

-- Set default for rows where role was empty
UPDATE users SET roles = ARRAY['student'] WHERE array_length(roles, 1) IS NULL OR array_length(roles, 1) = 0;

-- Drop old role column
ALTER TABLE users DROP COLUMN IF EXISTS role;

-- Add index for fast role-based lookups
CREATE INDEX IF NOT EXISTS idx_users_roles ON users USING GIN (roles);
