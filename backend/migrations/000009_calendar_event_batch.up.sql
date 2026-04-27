-- ============================================================
-- Migration 000009: add batch_id to platform.calendar_events
-- Used by calendar cross-domain listeners to locate every
-- class_session event for a given course batch (e.g. when a
-- facilitator gets approved and must be added to all classes).
-- ============================================================

ALTER TABLE platform.calendar_events ADD COLUMN batch_id UUID NULL;
CREATE INDEX idx_calendar_events_batch_id ON platform.calendar_events(batch_id);
