-- 050_create_delegations.sql
-- Creates the delegations table for the Delegation system.

CREATE TABLE IF NOT EXISTS delegations (
    id                  UUID PRIMARY KEY,
    title               VARCHAR(255)        NOT NULL,
    type                VARCHAR(50)         NOT NULL CHECK (type IN ('request_course', 'request_project', 'delegate_task')),
    description         TEXT                NOT NULL DEFAULT '',
    requested_by_id     UUID                NOT NULL,
    requested_by_name   VARCHAR(255)        NOT NULL DEFAULT '',
    assigned_to_id      UUID,
    assigned_to_name    VARCHAR(255)        NOT NULL DEFAULT '',
    assigned_to_role    VARCHAR(100)        NOT NULL DEFAULT '',
    due_date            TIMESTAMPTZ,
    priority            VARCHAR(20)         NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
    status              VARCHAR(20)         NOT NULL CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')) DEFAULT 'pending',
    linked_entity_type  VARCHAR(100),
    linked_entity_id    UUID,
    notes               TEXT,
    created_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_delegations_status ON delegations (status);
CREATE INDEX IF NOT EXISTS idx_delegations_type ON delegations (type);
CREATE INDEX IF NOT EXISTS idx_delegations_requested_by_id ON delegations (requested_by_id);
CREATE INDEX IF NOT EXISTS idx_delegations_assigned_to_id ON delegations (assigned_to_id);
CREATE INDEX IF NOT EXISTS idx_delegations_created_at ON delegations (created_at DESC);
