-- Master Course: entitas utama kursus VernonEdu
-- Setiap kursus memiliki bidang (field) tertentu seperti coding, culinary, barber, dst.
-- core_competencies menyimpan daftar kompetensi inti sebagai array JSON string
CREATE TABLE master_courses (
    id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    course_code       VARCHAR(50)  NOT NULL UNIQUE,
    course_name       VARCHAR(255) NOT NULL,
    field             VARCHAR(100) NOT NULL,                   -- coding, culinary, barber, dst
    core_competencies JSONB        NOT NULL DEFAULT '[]',      -- array of string
    description       TEXT         NOT NULL DEFAULT '',
    status            VARCHAR(20)  NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'archived')),
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Indeks untuk filter berdasarkan status dan bidang kursus
CREATE INDEX idx_master_courses_status ON master_courses(status);
CREATE INDEX idx_master_courses_field  ON master_courses(field);
