-- Course Module: modul pembelajaran yang menyusun sebuah course version
-- Urutan modul ditentukan oleh kolom sequence; module_code bersifat label (M1, M2, dst)
-- is_reference digunakan jika modul hanya merujuk ke modul master tanpa menyalin konten
CREATE TABLE course_modules (
    id                   UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    course_version_id    UUID         NOT NULL REFERENCES course_versions(id) ON DELETE CASCADE,
    module_code          VARCHAR(20)  NOT NULL,                -- kode tampilan: M1, M2, M3, dst
    module_title         VARCHAR(255) NOT NULL,
    duration_hours       DECIMAL(5,1) NOT NULL DEFAULT 0,      -- total jam pembelajaran modul ini
    sequence             INTEGER      NOT NULL DEFAULT 1,      -- urutan tampil dalam kurikulum
    content_depth        VARCHAR(20)  NOT NULL DEFAULT 'standard' CHECK (content_depth IN (
                             'intro', 'standard', 'advanced'
                         )),
    topics               JSONB        NOT NULL DEFAULT '[]',   -- daftar topik yang dibahas (array string)
    practical_activities JSONB        NOT NULL DEFAULT '[]',   -- daftar aktivitas praktik (array string)
    assessment_method    TEXT,                                 -- deskripsi cara penilaian modul ini
    tools_required       JSONB        NOT NULL DEFAULT '[]',   -- daftar alat/software yang dibutuhkan (array string)

    -- Jika true, modul ini hanya referensi ke modul lain; konten tidak disalin
    is_reference         BOOLEAN      NOT NULL DEFAULT false,
    ref_module_id        UUID,                                 -- FK ke course_modules.id jika is_reference = true

    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Indeks untuk join dari queries dan pengurutan modul dalam sebuah versi
CREATE INDEX idx_course_modules_version_id ON course_modules(course_version_id);
CREATE INDEX idx_course_modules_sequence   ON course_modules(course_version_id, sequence);
