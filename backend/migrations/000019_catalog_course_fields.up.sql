ALTER TABLE catalog.courses
  ADD COLUMN code          TEXT    NOT NULL DEFAULT '',
  ADD COLUMN description   TEXT    NOT NULL DEFAULT '',
  ADD COLUMN duration_days INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN format        TEXT    NOT NULL DEFAULT 'online'
    CHECK (format IN ('online', 'offline', 'hybrid')),
  ADD COLUMN status        TEXT    NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive'));

CREATE UNIQUE INDEX idx_courses_code ON catalog.courses(code) WHERE code <> '';
