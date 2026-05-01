DROP INDEX IF EXISTS franchise.idx_franchisees_user_id;
ALTER TABLE franchise.franchisees DROP COLUMN IF EXISTS user_id;
