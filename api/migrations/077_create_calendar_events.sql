CREATE TABLE IF NOT EXISTS calendar_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    event_type      VARCHAR(50) NOT NULL,
    start_at        TIMESTAMPTZ NOT NULL,
    end_at          TIMESTAMPTZ NOT NULL,
    is_all_day      BOOLEAN NOT NULL DEFAULT false,
    recurrence_rule VARCHAR(255),
    location        VARCHAR(500),
    source_domain   VARCHAR(50),
    source_id       UUID,
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_start_at ON calendar_events (start_at);
CREATE INDEX IF NOT EXISTS idx_calendar_events_source ON calendar_events (source_domain, source_id);
