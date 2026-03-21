-- Course Version: setiap course type memiliki versi independen menggunakan semantic versioning
-- Status versi: draft → review → approved → archived
-- Hanya versi berstatus 'approved' yang bisa digunakan untuk enrollment batch
CREATE TABLE course_versions (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    course_type_id  UUID         NOT NULL REFERENCES course_types(id) ON DELETE CASCADE,
    version_number  VARCHAR(20)  NOT NULL,                     -- contoh: '1.0.0', '2.1.3'
    status          VARCHAR(20)  NOT NULL DEFAULT 'draft' CHECK (status IN (
                        'draft', 'review', 'approved', 'archived'
                    )),
    -- Jenis perubahan dari versi sebelumnya
    change_type     VARCHAR(10)  NOT NULL DEFAULT 'minor' CHECK (change_type IN ('major', 'minor', 'patch')),
    changelog       TEXT         NOT NULL DEFAULT '',          -- catatan perubahan dari versi sebelumnya
    created_by      UUID         REFERENCES users(id),        -- admin/instruktur yang membuat versi ini
    approved_by     UUID         REFERENCES users(id),        -- admin yang menyetujui versi ini
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    approved_at     TIMESTAMPTZ,                              -- waktu versi disetujui
    archived_at     TIMESTAMPTZ,                              -- waktu versi diarsipkan

    -- Satu course type tidak boleh memiliki nomor versi yang sama lebih dari sekali
    UNIQUE(course_type_id, version_number)
);

-- Indeks untuk join dari course_modules dan filter berdasarkan status
CREATE INDEX idx_course_versions_type_id ON course_versions(course_type_id);
CREATE INDEX idx_course_versions_status  ON course_versions(status);
