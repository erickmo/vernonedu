-- ============================================================
-- Seed data: Batch, Student, Enrollment untuk testing
-- ============================================================

DO $$
DECLARE
  wdf_id UUID := 'a1000000-0000-0000-0000-000000000001';  -- WDF-001
  pkd_id UUID := 'a1000000-0000-0000-0000-000000000002';  -- PKD-001
  old_course_id1 UUID := '648d9b08-fa36-4cd0-b40a-39cd3d7db733';  -- Public Speaking (old)
  old_course_id2 UUID := 'ffe5ba30-cd4f-4357-a0f3-81d6fcf67105';  -- Social Media (old)
  admin_id UUID := '8fecdb60-02cf-4db8-af2a-9bca02af6e5a';

  -- Batch IDs
  b1 UUID; b2 UUID; b3 UUID; b4 UUID; b5 UUID; b6 UUID; b7 UUID;
  -- Student IDs
  s1 UUID; s2 UUID; s3 UUID; s4 UUID; s5 UUID;
  s6 UUID; s7 UUID; s8 UUID; s9 UUID; s10 UUID;
BEGIN

  -- ── BATCHES untuk WDF-001 (Web Dev Fullstack) ────────────────────────────────
  INSERT INTO course_batches (id, course_id, master_course_id, name, start_date, end_date,
    facilitator_id, max_participants, is_active, status, session_count, location)
  VALUES
    (gen_random_uuid(), old_course_id1, wdf_id,
     'WDF Batch 1 - Januari 2025', '2025-01-06', '2025-03-28',
     admin_id, 30, TRUE, 'completed', 36, 'Kelas A - Gedung Utama')
  RETURNING id INTO b1;

  INSERT INTO course_batches (id, course_id, master_course_id, name, start_date, end_date,
    facilitator_id, max_participants, is_active, status, session_count, location)
  VALUES
    (gen_random_uuid(), old_course_id1, wdf_id,
     'WDF Batch 2 - April 2025', '2025-04-07', '2025-06-27',
     admin_id, 25, TRUE, 'completed', 36, 'Kelas B - Gedung Utama')
  RETURNING id INTO b2;

  INSERT INTO course_batches (id, course_id, master_course_id, name, start_date, end_date,
    facilitator_id, max_participants, is_active, status, session_count, location)
  VALUES
    (gen_random_uuid(), old_course_id1, wdf_id,
     'WDF Batch 3 - Juli 2025', '2025-07-07', '2025-09-26',
     admin_id, 30, TRUE, 'completed', 36, 'Online via Zoom')
  RETURNING id INTO b3;

  INSERT INTO course_batches (id, course_id, master_course_id, name, start_date, end_date,
    facilitator_id, max_participants, is_active, status, session_count, location)
  VALUES
    (gen_random_uuid(), old_course_id2, wdf_id,
     'WDF Batch 4 - Januari 2026', '2026-01-06', '2026-03-27',
     admin_id, 30, TRUE, 'ongoing', 36, 'Kelas A - Gedung Utama')
  RETURNING id INTO b4;

  INSERT INTO course_batches (id, course_id, master_course_id, name, start_date, end_date,
    facilitator_id, max_participants, is_active, status, session_count, location)
  VALUES
    (gen_random_uuid(), old_course_id2, wdf_id,
     'WDF Batch 5 - April 2026', '2026-04-06', '2026-06-26',
     admin_id, 30, TRUE, 'upcoming', 36, 'Kelas B - Gedung Utama')
  RETURNING id INTO b5;

  -- ── BATCHES untuk PKD-001 (Program Karir Digital) ────────────────────────────
  INSERT INTO course_batches (id, course_id, master_course_id, name, start_date, end_date,
    facilitator_id, max_participants, is_active, status, session_count, location)
  VALUES
    (gen_random_uuid(), old_course_id1, pkd_id,
     'PKD Batch 1 - Agustus 2025', '2025-08-04', '2026-01-30',
     admin_id, 20, TRUE, 'completed', 48, 'Blended - Kelas + Online')
  RETURNING id INTO b6;

  INSERT INTO course_batches (id, course_id, master_course_id, name, start_date, end_date,
    facilitator_id, max_participants, is_active, status, session_count, location)
  VALUES
    (gen_random_uuid(), old_course_id2, pkd_id,
     'PKD Batch 2 - Maret 2026', '2026-03-02', '2026-08-28',
     admin_id, 20, TRUE, 'ongoing', 48, 'Kelas A - Gedung Utama')
  RETURNING id INTO b7;

  -- ── STUDENTS (10 orang) ──────────────────────────────────────────────────────
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Andi Pratama', 'andi.pratama@email.com', '081234567890', TRUE)
  RETURNING id INTO s1;
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Budi Santoso', 'budi.santoso@email.com', '081234567891', TRUE)
  RETURNING id INTO s2;
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Citra Dewi', 'citra.dewi@email.com', '081234567892', TRUE)
  RETURNING id INTO s3;
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Dian Novita', 'dian.novita@email.com', '081234567893', TRUE)
  RETURNING id INTO s4;
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Eko Prasetyo', 'eko.prasetyo@email.com', '081234567894', TRUE)
  RETURNING id INTO s5;
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Fitri Handayani', 'fitri.handayani@email.com', '081234567895', TRUE)
  RETURNING id INTO s6;
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Galih Wibowo', 'galih.wibowo@email.com', '081234567896', TRUE)
  RETURNING id INTO s7;
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Hana Permata', 'hana.permata@email.com', '081234567897', TRUE)
  RETURNING id INTO s8;
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Irfan Maulana', 'irfan.maulana@email.com', '081234567898', TRUE)
  RETURNING id INTO s9;
  INSERT INTO students (name, email, phone, is_active) VALUES
    ('Joko Widodo', 'joko.widodo123@email.com', '081234567899', TRUE)
  RETURNING id INTO s10;

  -- ── ENROLLMENTS ─────────────────────────────────────────────────────────────
  -- Batch 1 (WDF, completed) - 8 siswa
  INSERT INTO enrollments (student_id, course_batch_id, status, payment_status) VALUES
    (s1, b1, 'completed', 'paid'),
    (s2, b1, 'completed', 'paid'),
    (s3, b1, 'completed', 'paid'),
    (s4, b1, 'dropped', 'paid'),
    (s5, b1, 'completed', 'paid'),
    (s6, b1, 'completed', 'paid'),
    (s7, b1, 'completed', 'paid'),
    (s8, b1, 'completed', 'paid');

  -- Batch 2 (WDF, completed) - 6 siswa
  INSERT INTO enrollments (student_id, course_batch_id, status, payment_status) VALUES
    (s1, b2, 'completed', 'paid'),
    (s3, b2, 'completed', 'paid'),
    (s9, b2, 'completed', 'paid'),
    (s10, b2, 'completed', 'paid'),
    (s2, b2, 'completed', 'paid'),
    (s5, b2, 'completed', 'paid');

  -- Batch 3 (WDF, completed) - 5 siswa
  INSERT INTO enrollments (student_id, course_batch_id, status, payment_status) VALUES
    (s4, b3, 'completed', 'paid'),
    (s6, b3, 'completed', 'paid'),
    (s7, b3, 'completed', 'paid'),
    (s8, b3, 'completed', 'paid'),
    (s9, b3, 'completed', 'paid');

  -- Batch 4 (WDF, ongoing) - 7 siswa aktif
  INSERT INTO enrollments (student_id, course_batch_id, status, payment_status) VALUES
    (s1, b4, 'active', 'paid'),
    (s2, b4, 'active', 'paid'),
    (s3, b4, 'active', 'paid'),
    (s4, b4, 'active', 'paid'),
    (s5, b4, 'active', 'paid'),
    (s6, b4, 'active', 'pending'),
    (s10, b4, 'active', 'paid');

  -- Batch 5 (WDF, upcoming) - 3 enrolled
  INSERT INTO enrollments (student_id, course_batch_id, status, payment_status) VALUES
    (s7, b5, 'active', 'pending'),
    (s8, b5, 'active', 'pending'),
    (s9, b5, 'active', 'pending');

  -- Batch 6 (PKD, completed) - 5 siswa
  INSERT INTO enrollments (student_id, course_batch_id, status, payment_status) VALUES
    (s1, b6, 'completed', 'paid'),
    (s2, b6, 'completed', 'paid'),
    (s3, b6, 'completed', 'paid'),
    (s4, b6, 'dropped', 'paid'),
    (s5, b6, 'completed', 'paid');

  -- Batch 7 (PKD, ongoing) - 4 siswa
  INSERT INTO enrollments (student_id, course_batch_id, status, payment_status) VALUES
    (s6, b7, 'active', 'paid'),
    (s7, b7, 'active', 'paid'),
    (s8, b7, 'active', 'paid'),
    (s9, b7, 'active', 'pending');

  RAISE NOTICE 'Seed data batch dan siswa berhasil diisi';
END $$;
