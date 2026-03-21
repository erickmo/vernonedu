-- Tambah kolom master_course_id ke course_batches untuk linking ke kurikulum baru
ALTER TABLE course_batches ADD COLUMN IF NOT EXISTS master_course_id UUID;
CREATE INDEX IF NOT EXISTS idx_course_batches_master_course ON course_batches(master_course_id);

-- Tambah kolom status batch (untuk berjalan/selesai)
ALTER TABLE course_batches ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'upcoming';
-- status: upcoming | ongoing | completed | cancelled

-- Tambah kolom sesi_count
ALTER TABLE course_batches ADD COLUMN IF NOT EXISTS session_count INT NOT NULL DEFAULT 0;
ALTER TABLE course_batches ADD COLUMN IF NOT EXISTS location VARCHAR(255) NOT NULL DEFAULT '';
ALTER TABLE course_batches ADD COLUMN IF NOT EXISTS notes TEXT NOT NULL DEFAULT '';
