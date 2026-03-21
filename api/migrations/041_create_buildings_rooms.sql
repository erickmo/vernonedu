-- Migration 041: Create buildings, rooms, and batch_schedules tables

CREATE TABLE IF NOT EXISTS buildings (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255) NOT NULL,
    address     TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rooms (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    capacity    INT,
    floor       VARCHAR(50),
    facilities  TEXT[] NOT NULL DEFAULT '{}',
    description TEXT NOT NULL DEFAULT '',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rooms_building ON rooms(building_id);

-- batch_schedules: links a batch session to a module + room with time slot
CREATE TABLE IF NOT EXISTS batch_schedules (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id     UUID NOT NULL REFERENCES course_batches(id) ON DELETE CASCADE,
    module_id    UUID REFERENCES course_modules(id) ON DELETE SET NULL,
    room_id      UUID REFERENCES rooms(id) ON DELETE SET NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    duration_min INT NOT NULL DEFAULT 120,
    end_at       TIMESTAMPTZ NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_batch_schedules_batch  ON batch_schedules(batch_id);
CREATE INDEX IF NOT EXISTS idx_batch_schedules_room   ON batch_schedules(room_id);
CREATE INDEX IF NOT EXISTS idx_batch_schedules_time   ON batch_schedules(room_id, scheduled_at, end_at);
