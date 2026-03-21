ALTER TABLE course_modules
  ADD COLUMN IF NOT EXISTS requirements TEXT[] NOT NULL DEFAULT '{}';
