-- 079_add_building_ownership.sql

ALTER TABLE buildings
  ADD COLUMN ownership VARCHAR(10) NOT NULL DEFAULT 'self'
    CHECK (ownership IN ('self', 'partner')),
  ADD COLUMN partner_id UUID REFERENCES partners(id) ON DELETE SET NULL;

ALTER TABLE buildings
  ADD CONSTRAINT chk_building_partner_ownership
    CHECK (ownership = 'self' OR partner_id IS NOT NULL);
