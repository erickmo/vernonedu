CREATE TABLE holidays (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date       DATE NOT NULL,
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (date)
);

CREATE INDEX idx_holidays_date ON holidays(date);
