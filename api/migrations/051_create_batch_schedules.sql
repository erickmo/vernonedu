CREATE TABLE IF NOT EXISTS batch_schedules (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_batch_id  UUID NOT NULL REFERENCES course_batches(id) ON DELETE CASCADE,
    module_id        UUID REFERENCES course_modules(id) ON DELETE SET NULL,
    room_id          UUID REFERENCES rooms(id) ON DELETE SET NULL,
    scheduled_at     TIMESTAMPTZ NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 60,
    notes            TEXT NOT NULL DEFAULT '',
    status           VARCHAR(20) NOT NULL DEFAULT 'scheduled'
                       CHECK (status IN ('scheduled','completed','cancelled')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_batch_schedules_batch  ON batch_schedules(course_batch_id);
CREATE INDEX IF NOT EXISTS idx_batch_schedules_room   ON batch_schedules(room_id, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_batch_schedules_time   ON batch_schedules(scheduled_at);
