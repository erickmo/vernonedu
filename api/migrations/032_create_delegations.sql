CREATE TABLE IF NOT EXISTS delegations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'delegate_task',
    description TEXT NOT NULL DEFAULT '',
    assigned_to_id UUID,
    assigned_to_name TEXT NOT NULL DEFAULT '',
    assigned_by_id UUID,
    assigned_by_name TEXT NOT NULL DEFAULT '',
    priority TEXT NOT NULL DEFAULT 'medium',
    deadline TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'pending',
    linked_entity_id TEXT NOT NULL DEFAULT '',
    linked_entity_type TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
