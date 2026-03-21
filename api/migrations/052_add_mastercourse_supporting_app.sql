ALTER TABLE master_courses
  ADD COLUMN IF NOT EXISTS supporting_app_url TEXT;
