-- TalentPool VernonEdu: kumpulan peserta program_karir yang lulus tes karakter
-- Peserta berstatus 'active' = siap ditempatkan; 'placed' = sudah ditempatkan; 'inactive' = tidak aktif
-- placement_history menyimpan riwayat penempatan kerja sebagai array JSON object
CREATE TABLE talentpool (
    id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Referensi peserta; UUID digunakan karena tabel students mungkin ada di sistem terpisah
    participant_id        UUID         NOT NULL,
    participant_name      VARCHAR(255) NOT NULL DEFAULT '',    -- nama disimpan langsung untuk kemudahan query
    participant_email     VARCHAR(255),

    -- Referensi kursus yang menjadi dasar masuknya peserta ke TalentPool
    master_course_id      UUID         NOT NULL REFERENCES master_courses(id),
    course_type_id        UUID         NOT NULL REFERENCES course_types(id),
    course_version_id     UUID         NOT NULL REFERENCES course_versions(id),

    -- Hasil tes karakter yang menjadi syarat masuk TalentPool
    character_test_result JSONB        NOT NULL DEFAULT '{}',  -- detail hasil tes lengkap
    test_score            DECIMAL(5,2),                        -- skor numerik dari tes karakter

    -- Status peserta di dalam TalentPool
    talentpool_status     VARCHAR(20)  NOT NULL DEFAULT 'active' CHECK (talentpool_status IN (
                              'active', 'placed', 'inactive'
                          )),

    -- Riwayat penempatan kerja; contoh entri: { "company": "PT X", "placed_at": "2024-01-01", "position": "..." }
    placement_history     JSONB        NOT NULL DEFAULT '[]',

    joined_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Indeks untuk query umum: cari berdasarkan peserta, kursus, atau status
CREATE INDEX idx_talentpool_participant   ON talentpool(participant_id);
CREATE INDEX idx_talentpool_master_course ON talentpool(master_course_id);
CREATE INDEX idx_talentpool_status        ON talentpool(talentpool_status);

-- Satu peserta hanya boleh masuk TalentPool satu kali per course version
CREATE UNIQUE INDEX idx_talentpool_unique_participant_version
    ON talentpool(participant_id, course_version_id);
