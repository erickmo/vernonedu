-- Character Test Config: konfigurasi tes karakter untuk tipe program_karir
-- Setiap course version bertipe program_karir hanya boleh memiliki satu konfigurasi tes karakter
-- Peserta yang melewati passing_threshold dan talentpool_eligible = true akan masuk TalentPool
CREATE TABLE character_test_configs (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    course_version_id   UUID         NOT NULL UNIQUE REFERENCES course_versions(id) ON DELETE CASCADE,

    -- Jenis tes yang digunakan: MBTI, DISC, atau custom (misal: tes internal VernonEdu)
    test_type           VARCHAR(20)  NOT NULL DEFAULT 'DISC' CHECK (test_type IN ('MBTI', 'DISC', 'custom')),
    test_provider       VARCHAR(255),                          -- nama penyedia/platform tes

    -- Nilai minimum (skala 0-100) yang harus dicapai peserta agar dianggap lulus tes karakter
    passing_threshold   DECIMAL(5,2) NOT NULL DEFAULT 70.0,

    -- Jika true dan peserta lulus, peserta otomatis dimasukkan ke TalentPool VernonEdu
    talentpool_eligible BOOLEAN      NOT NULL DEFAULT true,

    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
