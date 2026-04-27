DROP INDEX IF EXISTS platform.idx_calendar_events_batch_id;
ALTER TABLE platform.calendar_events DROP COLUMN IF EXISTS batch_id;
