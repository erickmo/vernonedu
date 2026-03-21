-- Internship Config: konfigurasi magang untuk tipe program_karir
-- Setiap course version bertipe program_karir hanya boleh memiliki satu konfigurasi magang
-- is_company_provided = true berarti lembaga VernonEdu yang mencarikan perusahaan mitra
CREATE TABLE internship_configs (
    id                   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    course_version_id    UUID         NOT NULL UNIQUE REFERENCES course_versions(id) ON DELETE CASCADE,
    partner_company_name VARCHAR(255),                         -- nama perusahaan mitra magang
    partner_company_id   UUID,                                 -- FK ke tabel companies jika sudah ada
    position_title       VARCHAR(255) NOT NULL DEFAULT '',     -- jabatan/posisi yang diisi peserta
    duration_weeks       INTEGER      NOT NULL DEFAULT 4,      -- durasi magang dalam minggu
    supervisor_name      VARCHAR(255),                         -- nama pembimbing dari perusahaan
    supervisor_contact   VARCHAR(255),                         -- kontak pembimbing (email/telepon)
    mou_document_url     TEXT,                                 -- URL dokumen MOU antara lembaga dan perusahaan

    -- true = lembaga yang mencarikan perusahaan; false = peserta mencari sendiri
    is_company_provided  BOOLEAN      NOT NULL DEFAULT true,

    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
