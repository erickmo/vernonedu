-- Seed data kurikulum VernonEdu
-- File ini bersifat idempotent: setiap blok dibungkus dalam DO...EXCEPTION agar aman dijalankan ulang
-- Semua UUID bersifat hardcoded agar data seed selalu konsisten dan dapat direproduksi

-- ============================================================
-- UUID REFERENSI
-- ============================================================
-- Master Courses
--   mc_webdev  = a1000000-0000-0000-0000-000000000001  (Web Development Fullstack)
--   mc_karir   = a1000000-0000-0000-0000-000000000002  (Program Karir Digital)
--
-- Course Types
--   ct_webdev_regular  = b1000000-0000-0000-0000-000000000001
--   ct_webdev_private  = b1000000-0000-0000-0000-000000000002
--   ct_karir_pk        = b1000000-0000-0000-0000-000000000003
--
-- Course Versions
--   cv_webdev_reg_v1   = c1000000-0000-0000-0000-000000000001  (regular v1.0.0 approved)
--   cv_webdev_reg_v2   = c1000000-0000-0000-0000-000000000002  (regular v2.0.0 draft)
--   cv_webdev_priv_v1  = c1000000-0000-0000-0000-000000000003  (private v1.0.0 approved)
--   cv_karir_v1        = c1000000-0000-0000-0000-000000000004  (program_karir v1.0.0 approved)
--
-- TalentPool Participants
--   tp_peserta_1       = e1000000-0000-0000-0000-000000000001
--   tp_peserta_2       = e1000000-0000-0000-0000-000000000002
-- ============================================================


-- ------------------------------------------------------------
-- 1. Master Courses
-- ------------------------------------------------------------

DO $$ BEGIN
    INSERT INTO master_courses (
        id, course_code, course_name, field,
        core_competencies, description, status
    ) VALUES (
        'a1000000-0000-0000-0000-000000000001',
        'WDF-001',
        'Web Development Fullstack',
        'coding',
        '["HTML & CSS", "JavaScript", "React", "Node.js", "PostgreSQL", "Git & Version Control"]',
        'Kursus pemrograman web dari sisi frontend hingga backend. Peserta akan mampu membangun aplikasi web fullstack yang siap produksi.',
        'active'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
    INSERT INTO master_courses (
        id, course_code, course_name, field,
        core_competencies, description, status
    ) VALUES (
        'a1000000-0000-0000-0000-000000000002',
        'PKD-001',
        'Program Karir Digital',
        'coding',
        '["Pemrograman Dasar", "Logika Algoritma", "Tes Karakter & Soft Skill", "Magang Industri Digital"]',
        'Program intensif menuju karir di industri digital. Mencakup pembelajaran teknis, tes karakter, dan magang di perusahaan mitra VernonEdu.',
        'active'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;


-- ------------------------------------------------------------
-- 2. Course Types
-- ------------------------------------------------------------

-- Web Development Fullstack - Regular
DO $$ BEGIN
    INSERT INTO course_types (
        id, master_course_id, type_name, is_active,
        price_type, price_min, price_max, price_currency, price_notes,
        target_audience, certification_type,
        component_failure_config
    ) VALUES (
        'b1000000-0000-0000-0000-000000000001',
        'a1000000-0000-0000-0000-000000000001',
        'regular',
        true,
        'fixed', 5000000, 5000000, 'IDR',
        'Harga sudah termasuk modul, akses platform, dan sertifikat kelulusan.',
        'Pelajar SMA/SMK, mahasiswa, dan umum yang ingin belajar web development dari nol.',
        'internal',
        NULL
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Web Development Fullstack - Private
DO $$ BEGIN
    INSERT INTO course_types (
        id, master_course_id, type_name, is_active,
        price_type, price_min, price_max, price_currency, price_notes,
        target_audience, certification_type,
        component_failure_config
    ) VALUES (
        'b1000000-0000-0000-0000-000000000002',
        'a1000000-0000-0000-0000-000000000001',
        'private',
        true,
        'range', 8000000, 15000000, 'IDR',
        'Harga bervariasi tergantung jadwal, jumlah sesi, dan kebutuhan kurikulum khusus.',
        'Profesional atau individu yang ingin belajar dengan jadwal fleksibel dan kurikulum disesuaikan.',
        'internal',
        NULL
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Program Karir Digital - Program Karir
DO $$ BEGIN
    INSERT INTO course_types (
        id, master_course_id, type_name, is_active,
        price_type, price_min, price_max, price_currency, price_notes,
        target_audience, certification_type,
        component_failure_config
    ) VALUES (
        'b1000000-0000-0000-0000-000000000003',
        'a1000000-0000-0000-0000-000000000002',
        'program_karir',
        true,
        'fixed', 7500000, 7500000, 'IDR',
        'Termasuk biaya pembelajaran, fasilitasi magang, dan tes karakter.',
        'Lulusan SMA/SMK/D3/S1 yang ingin memulai karir di industri digital dengan dukungan penempatan kerja.',
        'career_certificate',
        '{
            "pembelajaran": "retry",
            "magang": "disqualified",
            "character_test": "continue_no_cert"
        }'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;


-- ------------------------------------------------------------
-- 3. Course Versions
-- ------------------------------------------------------------

-- Web Development Fullstack - Regular v1.0.0 (approved)
DO $$ BEGIN
    INSERT INTO course_versions (
        id, course_type_id, version_number, status,
        change_type, changelog,
        approved_at
    ) VALUES (
        'c1000000-0000-0000-0000-000000000001',
        'b1000000-0000-0000-0000-000000000001',
        '1.0.0',
        'approved',
        'major',
        'Versi pertama kurikulum Web Development Fullstack kelas regular. Mencakup HTML/CSS, JavaScript, dan React.',
        '2024-06-01 00:00:00+00'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Web Development Fullstack - Regular v2.0.0 (draft)
DO $$ BEGIN
    INSERT INTO course_versions (
        id, course_type_id, version_number, status,
        change_type, changelog
    ) VALUES (
        'c1000000-0000-0000-0000-000000000002',
        'b1000000-0000-0000-0000-000000000001',
        '2.0.0',
        'draft',
        'major',
        'Pembaruan besar: penambahan modul Node.js dan PostgreSQL; React diperbarui ke versi terbaru; restrukturisasi urutan modul.'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Web Development Fullstack - Private v1.0.0 (approved)
DO $$ BEGIN
    INSERT INTO course_versions (
        id, course_type_id, version_number, status,
        change_type, changelog,
        approved_at
    ) VALUES (
        'c1000000-0000-0000-0000-000000000003',
        'b1000000-0000-0000-0000-000000000002',
        '1.0.0',
        'approved',
        'major',
        'Versi pertama kurikulum Web Development kelas private. Konten identik dengan regular namun dengan kecepatan dan penyesuaian per peserta.',
        '2024-06-15 00:00:00+00'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Program Karir Digital - Program Karir v1.0.0 (approved)
DO $$ BEGIN
    INSERT INTO course_versions (
        id, course_type_id, version_number, status,
        change_type, changelog,
        approved_at
    ) VALUES (
        'c1000000-0000-0000-0000-000000000004',
        'b1000000-0000-0000-0000-000000000003',
        '1.0.0',
        'approved',
        'major',
        'Versi pertama Program Karir Digital. Mencakup pembelajaran dasar coding, tes karakter DISC, dan magang 4 minggu di perusahaan mitra.',
        '2024-07-01 00:00:00+00'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;


-- ------------------------------------------------------------
-- 4. Course Modules
-- ------------------------------------------------------------

-- === Regular v1.0.0: 3 modul ===

-- Modul 1: HTML & CSS
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000001',
        'c1000000-0000-0000-0000-000000000001',
        'M1', 'Dasar HTML & CSS',
        20.0, 1, 'intro',
        '["Struktur dokumen HTML5", "Selektor dan properti CSS", "Flexbox dan Grid Layout", "Responsive Design dengan Media Query"]',
        '["Membangun halaman profil pribadi", "Kloning layout website populer", "Membuat landing page responsif"]',
        'Proyek akhir: membuat website portofolio statis yang responsif dan sesuai standar aksesibilitas.',
        '["VS Code", "Browser DevTools", "Git"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Modul 2: JavaScript
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000002',
        'c1000000-0000-0000-0000-000000000001',
        'M2', 'JavaScript Dasar hingga Menengah',
        30.0, 2, 'standard',
        '["Tipe data dan variabel", "Fungsi dan scope", "DOM Manipulation", "Fetch API dan async/await", "ES6+ modern syntax"]',
        '["Membuat kalkulator interaktif", "Aplikasi to-do list dengan localStorage", "Mengonsumsi REST API publik"]',
        'Quiz mingguan + proyek akhir: aplikasi web single-page yang mengonsumsi API eksternal.',
        '["VS Code", "Browser DevTools", "Node.js (untuk testing lokal)"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Modul 3: React
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000003',
        'c1000000-0000-0000-0000-000000000001',
        'M3', 'React untuk Frontend Modern',
        35.0, 3, 'standard',
        '["Komponen dan props", "State management dengan useState dan useReducer", "Side effects dengan useEffect", "React Router", "Context API"]',
        '["Membangun aplikasi CRUD dengan React", "Integrasi React dengan REST API", "Deploy aplikasi ke Vercel"]',
        'Proyek akhir: aplikasi web fullstack sederhana dengan React frontend dan REST API.',
        '["VS Code", "Node.js", "npm/yarn", "Vite", "Git"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- === Regular v2.0.0: 3 modul (draft) ===

-- Modul 1: HTML & CSS (versi draft)
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000004',
        'c1000000-0000-0000-0000-000000000002',
        'M1', 'Dasar HTML & CSS',
        20.0, 1, 'intro',
        '["Struktur dokumen HTML5", "Selektor dan properti CSS", "Flexbox dan Grid Layout", "Responsive Design dengan Media Query", "CSS Custom Properties (Variables)"]',
        '["Membangun halaman profil pribadi", "Kloning layout website populer", "Membuat landing page responsif"]',
        'Proyek akhir: membuat website portofolio statis yang responsif dan sesuai standar aksesibilitas.',
        '["VS Code", "Browser DevTools", "Git"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Modul 2: JavaScript (versi draft)
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000005',
        'c1000000-0000-0000-0000-000000000002',
        'M2', 'JavaScript Dasar hingga Menengah',
        30.0, 2, 'standard',
        '["Tipe data dan variabel", "Fungsi dan scope", "DOM Manipulation", "Fetch API dan async/await", "ES6+ modern syntax", "TypeScript dasar"]',
        '["Membuat kalkulator interaktif", "Aplikasi to-do list dengan localStorage", "Mengonsumsi REST API publik"]',
        'Quiz mingguan + proyek akhir: aplikasi web single-page yang mengonsumsi API eksternal.',
        '["VS Code", "Browser DevTools", "Node.js", "TypeScript"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Modul 3: React (versi draft)
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000006',
        'c1000000-0000-0000-0000-000000000002',
        'M3', 'React dan Node.js Fullstack',
        45.0, 3, 'advanced',
        '["React hooks lanjutan", "State management dengan Zustand", "Node.js dan Express", "REST API dengan PostgreSQL", "Deploy fullstack ke cloud"]',
        '["Membangun API RESTful dengan Node.js", "Integrasi React + Node.js + PostgreSQL", "Deploy ke Railway dan Vercel"]',
        'Proyek akhir: aplikasi web fullstack lengkap dengan autentikasi dan database.',
        '["VS Code", "Node.js", "npm", "Vite", "PostgreSQL", "Git"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- === Private v1.0.0: 3 modul ===

-- Modul 1: HTML & CSS (private)
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000007',
        'c1000000-0000-0000-0000-000000000003',
        'M1', 'Dasar HTML & CSS',
        20.0, 1, 'intro',
        '["Struktur dokumen HTML5", "Selektor dan properti CSS", "Flexbox dan Grid Layout", "Responsive Design dengan Media Query"]',
        '["Membangun halaman profil pribadi", "Kloning layout website populer", "Membuat landing page responsif"]',
        'Proyek akhir disesuaikan dengan kebutuhan dan tujuan karir peserta.',
        '["VS Code", "Browser DevTools", "Git"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Modul 2: JavaScript (private)
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000008',
        'c1000000-0000-0000-0000-000000000003',
        'M2', 'JavaScript Dasar hingga Menengah',
        30.0, 2, 'standard',
        '["Tipe data dan variabel", "Fungsi dan scope", "DOM Manipulation", "Fetch API dan async/await", "ES6+ modern syntax"]',
        '["Membuat kalkulator interaktif", "Aplikasi to-do list dengan localStorage", "Mengonsumsi REST API publik"]',
        'Evaluasi dilakukan secara berkelanjutan melalui sesi 1-on-1 dengan instruktur.',
        '["VS Code", "Browser DevTools", "Node.js (untuk testing lokal)"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Modul 3: React (private)
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000009',
        'c1000000-0000-0000-0000-000000000003',
        'M3', 'React untuk Frontend Modern',
        35.0, 3, 'standard',
        '["Komponen dan props", "State management dengan useState dan useReducer", "Side effects dengan useEffect", "React Router", "Context API"]',
        '["Membangun aplikasi CRUD dengan React", "Integrasi React dengan REST API", "Deploy aplikasi ke Vercel"]',
        'Proyek akhir disesuaikan: peserta membangun fitur nyata sesuai konteks pekerjaan/bisnis masing-masing.',
        '["VS Code", "Node.js", "npm/yarn", "Vite", "Git"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- === Program Karir v1.0.0: 3 modul ===

-- Modul 1: Pemrograman Dasar
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000010',
        'c1000000-0000-0000-0000-000000000004',
        'M1', 'Pemrograman Dasar dan Logika Algoritma',
        25.0, 1, 'intro',
        '["Konsep dasar pemrograman", "Variabel, tipe data, dan operator", "Percabangan dan perulangan", "Fungsi dan modularisasi kode", "Pengenalan HTML & CSS"]',
        '["Membuat program kalkulator sederhana", "Memecahkan soal algoritma dasar", "Membangun halaman web statis pertama"]',
        'Tes tertulis dan praktik coding untuk mengukur pemahaman logika dasar sebelum lanjut ke tahap magang.',
        '["VS Code", "Browser", "Git"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Modul 2: Soft Skill dan Kesiapan Kerja
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000011',
        'c1000000-0000-0000-0000-000000000004',
        'M2', 'Soft Skill dan Kesiapan Karir Digital',
        15.0, 2, 'standard',
        '["Komunikasi profesional di lingkungan kerja", "Manajemen waktu dan produktivitas", "Kerja tim dan kolaborasi remote", "Personal branding dan LinkedIn", "Etika kerja di industri digital"]',
        '["Simulasi wawancara kerja", "Pembuatan profil LinkedIn yang profesional", "Role-play skenario komunikasi tim"]',
        'Evaluasi melalui simulasi wawancara dan presentasi diri di depan panel instruktur.',
        '["LinkedIn", "Zoom/Google Meet", "Google Workspace"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Modul 3: Tes Karakter dan Persiapan Magang
DO $$ BEGIN
    INSERT INTO course_modules (
        id, course_version_id, module_code, module_title,
        duration_hours, sequence, content_depth,
        topics, practical_activities, assessment_method, tools_required
    ) VALUES (
        'd1000000-0000-0000-0000-000000000012',
        'c1000000-0000-0000-0000-000000000004',
        'M3', 'Tes Karakter dan Orientasi Magang',
        10.0, 3, 'standard',
        '["Pengenalan tes DISC dan interpretasi hasil", "Memahami profil karakter diri sendiri", "Briefing prosedur magang", "Penandatanganan MOU peserta"]',
        '["Menjalani tes karakter DISC secara online", "Diskusi hasil tes bersama konselor karir", "Sesi orientasi perusahaan mitra"]',
        'Tes karakter DISC dengan passing threshold 70. Peserta yang lulus akan dimasukkan ke TalentPool VernonEdu.',
        '["Platform tes DISC online", "Zoom untuk sesi diskusi hasil"]'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;


-- ------------------------------------------------------------
-- 5. Internship Config (untuk Program Karir v1.0.0)
-- ------------------------------------------------------------

DO $$ BEGIN
    INSERT INTO internship_configs (
        id, course_version_id,
        partner_company_name, position_title,
        duration_weeks, supervisor_name, supervisor_contact,
        mou_document_url, is_company_provided
    ) VALUES (
        'f1000000-0000-0000-0000-000000000001',
        'c1000000-0000-0000-0000-000000000004',
        'PT Mitra Digital Nusantara',
        'Junior Web Developer Intern',
        4,
        'Budi Santoso',
        'budi.santoso@mitra-digital.co.id',
        'https://storage.vernonedu.id/mou/mou-mitra-digital-2024.pdf',
        true
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;


-- ------------------------------------------------------------
-- 6. Character Test Config (untuk Program Karir v1.0.0)
-- ------------------------------------------------------------

DO $$ BEGIN
    INSERT INTO character_test_configs (
        id, course_version_id,
        test_type, test_provider,
        passing_threshold, talentpool_eligible
    ) VALUES (
        'f2000000-0000-0000-0000-000000000001',
        'c1000000-0000-0000-0000-000000000004',
        'DISC',
        'Assessfirst by VernonEdu',
        70.00,
        true
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;


-- ------------------------------------------------------------
-- 7. TalentPool — 2 peserta fiktif yang lulus tes karakter
-- ------------------------------------------------------------

-- Peserta 1: Andi Pratama
DO $$ BEGIN
    INSERT INTO talentpool (
        id,
        participant_id,
        participant_name,
        participant_email,
        master_course_id,
        course_type_id,
        course_version_id,
        character_test_result,
        test_score,
        talentpool_status,
        placement_history,
        joined_at
    ) VALUES (
        'e1000000-0000-0000-0000-000000000001',
        'p1000000-0000-0000-0000-000000000001',  -- participant_id (peserta fiktif)
        'Andi Pratama',
        'andi.pratama@email.com',
        'a1000000-0000-0000-0000-000000000002',  -- Program Karir Digital
        'b1000000-0000-0000-0000-000000000003',  -- program_karir
        'c1000000-0000-0000-0000-000000000004',  -- v1.0.0
        '{
            "dominant_type": "D",
            "profile": "Dominance",
            "strengths": ["Berorientasi hasil", "Pengambil keputusan cepat", "Mandiri"],
            "areas_to_develop": ["Empati terhadap rekan tim", "Mendengarkan secara aktif"],
            "disc_breakdown": { "D": 78, "I": 55, "S": 42, "C": 61 }
        }',
        82.50,
        'active',
        '[]',
        '2024-09-15 08:00:00+00'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Peserta 2: Sari Wulandari (sudah ditempatkan)
DO $$ BEGIN
    INSERT INTO talentpool (
        id,
        participant_id,
        participant_name,
        participant_email,
        master_course_id,
        course_type_id,
        course_version_id,
        character_test_result,
        test_score,
        talentpool_status,
        placement_history,
        joined_at
    ) VALUES (
        'e1000000-0000-0000-0000-000000000002',
        'p1000000-0000-0000-0000-000000000002',  -- participant_id (peserta fiktif)
        'Sari Wulandari',
        'sari.wulandari@email.com',
        'a1000000-0000-0000-0000-000000000002',  -- Program Karir Digital
        'b1000000-0000-0000-0000-000000000003',  -- program_karir
        'c1000000-0000-0000-0000-000000000004',  -- v1.0.0
        '{
            "dominant_type": "I",
            "profile": "Influence",
            "strengths": ["Komunikasi efektif", "Antusias dan optimis", "Mudah membangun relasi"],
            "areas_to_develop": ["Fokus pada detail teknis", "Manajemen prioritas"],
            "disc_breakdown": { "D": 50, "I": 85, "S": 60, "C": 45 }
        }',
        91.00,
        'placed',
        '[
            {
                "company": "PT Inovasi Teknologi Bangsa",
                "position": "Junior Frontend Developer",
                "placed_at": "2024-11-01",
                "contract_type": "permanent",
                "notes": "Peserta berhasil lolos seleksi setelah 2 minggu di TalentPool."
            }
        ]',
        '2024-09-15 08:30:00+00'
    );
EXCEPTION WHEN OTHERS THEN NULL;
END $$;
