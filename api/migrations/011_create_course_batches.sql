CREATE TABLE IF NOT EXISTS course_batches (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id        UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  name             VARCHAR(255) NOT NULL,
  start_date       DATE NOT NULL,
  end_date         DATE NOT NULL,
  facilitator_id   UUID REFERENCES users(id) ON DELETE SET NULL,
  max_participants INT NOT NULL DEFAULT 30,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_course_batches_course ON course_batches(course_id);
