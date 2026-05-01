ALTER TABLE franchise.franchisees
  ADD COLUMN user_id UUID REFERENCES identity.users(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX idx_franchisees_user_id ON franchise.franchisees(user_id)
  WHERE user_id IS NOT NULL;
