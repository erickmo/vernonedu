CREATE TABLE job_vacancies (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    title            TEXT        NOT NULL,
    description      TEXT        NOT NULL DEFAULT '',
    partner_id       UUID        NOT NULL REFERENCES partners(id) ON DELETE RESTRICT,
    department_id    UUID        REFERENCES departments(id) ON DELETE SET NULL,
    location         TEXT        NOT NULL DEFAULT '',
    type             TEXT        NOT NULL DEFAULT 'full_time',
    status           TEXT        NOT NULL DEFAULT 'draft',
    experience_level TEXT        NOT NULL DEFAULT 'fresh_graduate',
    slots            INT         NOT NULL DEFAULT 1,
    min_salary       BIGINT,
    max_salary       BIGINT,
    required_skills  TEXT[]      NOT NULL DEFAULT '{}',
    deadline         DATE,
    created_by       UUID        NOT NULL REFERENCES users(id),
    deleted_at       TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_job_vacancies_status  ON job_vacancies(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_job_vacancies_partner ON job_vacancies(partner_id);
