-- Curriculum iter-1f-c: Add Course Version approval workflow.
-- Independent of the existing `status` lifecycle (draft|review|approved|archived),
-- this approval_status tracks the formal request/approval flow:
--   draft -> submitted (by course_owner) -> approved | rejected (by dept_leader)
ALTER TABLE course_versions
    ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (approval_status IN ('draft', 'submitted', 'approved', 'rejected')),
    ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS submitted_by UUID REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS approval_approved_by UUID REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS approval_approved_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_course_versions_approval_status
    ON course_versions(approval_status);
