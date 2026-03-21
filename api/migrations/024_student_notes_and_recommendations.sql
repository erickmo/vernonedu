-- ============================================================
-- Migration 024: Student Notes + Course Recommendations
-- ============================================================

-- Tambah kolom ke enrollments untuk tracking nilai dan kehadiran
ALTER TABLE enrollments ADD COLUMN IF NOT EXISTS final_score  NUMERIC(5,2);
ALTER TABLE enrollments ADD COLUMN IF NOT EXISTS grade        VARCHAR(5);
ALTER TABLE enrollments ADD COLUMN IF NOT EXISTS total_attendance INT NOT NULL DEFAULT 0;

-- Tabel catatan per siswa (ditulis oleh staf)
CREATE TABLE IF NOT EXISTS student_notes (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id  UUID        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    author_id   VARCHAR(255) NOT NULL DEFAULT '',
    author_name VARCHAR(255) NOT NULL DEFAULT '',
    content     TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_student_notes_student ON student_notes(student_id);

-- Tabel rekomendasi course per siswa
CREATE TABLE IF NOT EXISTS student_course_recommendations (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id       UUID        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    master_course_id UUID        NOT NULL REFERENCES master_courses(id) ON DELETE CASCADE,
    reason           TEXT        NOT NULL DEFAULT '',
    priority         INT         NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reco_student ON student_course_recommendations(student_id);

-- ============================================================
-- Seed: update enrollment data dengan nilai & kehadiran
-- ============================================================
DO $$
DECLARE
  wdf_id UUID := 'a1000000-0000-0000-0000-000000000001';
  pkd_id UUID := 'a1000000-0000-0000-0000-000000000002';
BEGIN

  -- Update enrollments completed dengan nilai dan kehadiran (WDF batch 1, 2, 3)
  UPDATE enrollments e
  SET final_score = CASE
        WHEN e.status = 'completed' THEN (75 + FLOOR(RANDOM() * 25))::NUMERIC
        ELSE NULL
      END,
      grade = CASE
        WHEN e.status = 'completed' AND (75 + FLOOR(RANDOM() * 25)) >= 90 THEN 'A'
        WHEN e.status = 'completed' AND (75 + FLOOR(RANDOM() * 25)) >= 80 THEN 'B'
        WHEN e.status = 'completed' THEN 'C'
        ELSE NULL
      END,
      total_attendance = CASE
        WHEN e.status = 'completed' THEN (28 + FLOOR(RANDOM() * 8))::INT
        WHEN e.status = 'active'    THEN (10 + FLOOR(RANDOM() * 15))::INT
        ELSE 0
      END
  WHERE e.student_id IN (SELECT id FROM students)
    AND e.status IN ('completed', 'active');

  -- ── Seed rekomendasi ─────────────────────────────────────────────────────────
  -- Siswa yang sudah ambil WDF → rekomendasikan PKD
  INSERT INTO student_course_recommendations (student_id, master_course_id, reason, priority)
  SELECT DISTINCT e.student_id,
                  pkd_id,
                  'Setelah menyelesaikan Web Development Fullstack, Program Karir Digital akan membantu kamu menempatkan keahlian di industri nyata.',
                  10
  FROM enrollments e
  JOIN course_batches cb ON cb.id = e.course_batch_id
  WHERE cb.master_course_id = wdf_id
    AND e.status = 'completed'
    AND NOT EXISTS (
        SELECT 1 FROM enrollments e2
        JOIN course_batches cb2 ON cb2.id = e2.course_batch_id
        WHERE e2.student_id = e.student_id AND cb2.master_course_id = pkd_id
    )
  ON CONFLICT DO NOTHING;

  -- Siswa yang sudah ambil PKD → rekomendasikan WDF (jika belum ambil)
  INSERT INTO student_course_recommendations (student_id, master_course_id, reason, priority)
  SELECT DISTINCT e.student_id,
                  wdf_id,
                  'Web Development Fullstack akan melengkapi skill teknis kamu dari Program Karir Digital yang telah selesai.',
                  8
  FROM enrollments e
  JOIN course_batches cb ON cb.id = e.course_batch_id
  WHERE cb.master_course_id = pkd_id
    AND e.status = 'completed'
    AND NOT EXISTS (
        SELECT 1 FROM enrollments e2
        JOIN course_batches cb2 ON cb2.id = e2.course_batch_id
        WHERE e2.student_id = e.student_id AND cb2.master_course_id = wdf_id
    )
  ON CONFLICT DO NOTHING;

  -- Siswa aktif di WDF → rekomendasikan PKD sebagai next step
  INSERT INTO student_course_recommendations (student_id, master_course_id, reason, priority)
  SELECT DISTINCT e.student_id,
                  pkd_id,
                  'Setelah batch Web Development ini selesai, Program Karir Digital adalah langkah selanjutnya yang tepat.',
                  5
  FROM enrollments e
  JOIN course_batches cb ON cb.id = e.course_batch_id
  WHERE cb.master_course_id = wdf_id
    AND e.status = 'active'
    AND NOT EXISTS (
        SELECT 1 FROM student_course_recommendations r
        WHERE r.student_id = e.student_id AND r.master_course_id = pkd_id
    )
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Migration 024: student_notes, recommendations, dan enrollment updates selesai';
END $$;
