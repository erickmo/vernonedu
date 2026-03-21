-- Course Type: setiap master course bisa memiliki 1 hingga 6 tipe pengiriman
-- Tipe yang tersedia: regular, private, company_training, collab_university, collab_school, program_karir
-- Harga bisa berupa angka tetap (fixed), rentang (range), atau berdasarkan permintaan (by_request)
CREATE TABLE course_types (
    id                       UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    master_course_id         UUID         NOT NULL REFERENCES master_courses(id) ON DELETE CASCADE,
    type_name                VARCHAR(50)  NOT NULL CHECK (type_name IN (
                                 'regular', 'private', 'company_training',
                                 'collab_university', 'collab_school', 'program_karir'
                             )),
    is_active                BOOLEAN      NOT NULL DEFAULT true,

    -- Konfigurasi harga: fixed = harga tetap, range = rentang harga, by_request = negosiasi
    price_type               VARCHAR(20)  NOT NULL DEFAULT 'fixed' CHECK (price_type IN ('fixed', 'range', 'by_request')),
    price_min                BIGINT,                            -- jika fixed: sama dengan price_max
    price_max                BIGINT,                            -- jika range: berbeda dari price_min
    price_currency           VARCHAR(10)  NOT NULL DEFAULT 'IDR',
    price_notes              TEXT,

    target_audience          TEXT,
    extra_docs               JSONB        NOT NULL DEFAULT '[]', -- dokumen tambahan yang wajib dilengkapi peserta

    -- Jenis sertifikasi yang diterbitkan setelah kursus selesai
    certification_type       VARCHAR(30)  NOT NULL DEFAULT 'internal' CHECK (certification_type IN (
                                 'internal', 'SKS', 'nilai_rapor', 'corporate', 'career_certificate'
                             )),

    -- Khusus program_karir: konfigurasi perilaku jika salah satu komponen gagal
    -- Contoh: { "pembelajaran": "retry", "magang": "disqualified", "character_test": "continue_no_cert" }
    component_failure_config JSONB,

    created_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    -- Satu master course tidak boleh memiliki tipe yang sama lebih dari sekali
    UNIQUE(master_course_id, type_name)
);

-- Indeks untuk join dari course_versions dan filter umum
CREATE INDEX idx_course_types_master_course ON course_types(master_course_id);
CREATE INDEX idx_course_types_type_name     ON course_types(type_name);
CREATE INDEX idx_course_types_is_active     ON course_types(is_active);
