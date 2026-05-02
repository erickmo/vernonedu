# Curriculum Iter-1f-c — Course Version Approval Workflow

**Date:** 2026-05-02
**Branch:** `feat/curriculum-version-approval`

## Context

`CourseVersion` already has a lifecycle `status` (`draft|review|approved|archived`)
used by `promote_courseversion`. This spec adds an **independent** approval
workflow used by Course Owners to formally request Department Leader approval
before a version can back a real `CourseBatch`.

## Goals

1. Track approval workflow on each `course_versions` row.
2. Enforce role-based gates (Course Owner submits, Dept Leader approves/rejects).
3. Allow listing of pending approvals (optionally filtered by department).
4. Block `CreateCourseBatch` when the referenced course version is not
   `approval_status='approved'`.

## Non-goals

- Automating the existing `Status` lifecycle from `approval_status`. The two
  fields are orthogonal; promotion remains a separate operation.
- Multi-step approval chains. This is a single-step approval (Dept Leader).

## Schema Change (migration 057)

```sql
ALTER TABLE course_versions
  ADD COLUMN approval_status   VARCHAR(20) NOT NULL DEFAULT 'draft'
    CHECK (approval_status IN ('draft','submitted','approved','rejected')),
  ADD COLUMN submitted_at      TIMESTAMPTZ,
  ADD COLUMN submitted_by      UUID REFERENCES users(id),
  ADD COLUMN approval_approved_by UUID REFERENCES users(id),
  ADD COLUMN approval_approved_at TIMESTAMPTZ,
  ADD COLUMN rejection_reason  TEXT;

CREATE INDEX idx_course_versions_approval_status ON course_versions(approval_status);
```

> Note: an existing `approved_by`/`approved_at` pair already tracks the
> *promotion* approver. We add a parallel pair (`approval_approved_by`,
> `approval_approved_at`) for the workflow approver to keep concerns separate.

## Domain (`internal/domain/courseversion`)

New constants:

```go
const (
    ApprovalStatusDraft     = "draft"
    ApprovalStatusSubmitted = "submitted"
    ApprovalStatusApproved  = "approved"
    ApprovalStatusRejected  = "rejected"
)
```

New fields on `CourseVersion`:

| Field | Type |
|---|---|
| ApprovalStatus | string |
| SubmittedAt | *time.Time |
| SubmittedBy | *uuid.UUID |
| ApprovalApprovedBy | *uuid.UUID |
| ApprovalApprovedAt | *time.Time |
| RejectionReason | string |

New methods (each ≤40 lines):

- `Submit(submittedBy uuid.UUID) error` — `draft → submitted`.
- `ApproveWorkflow(approvedBy uuid.UUID) error` — `submitted → approved`.
- `RejectWorkflow(approvedBy uuid.UUID, reason string) error` — `submitted → rejected`.

New repository methods:
- `WriteRepository.UpdateApprovalWorkflow(ctx, cv) error`
- `ReadRepository.ListPending(ctx, departmentID *uuid.UUID) ([]*CourseVersion, error)`

## Commands (CQRS)

### `submit_course_version`
- Fields: `VersionID uuid.UUID`, `SubmittedBy uuid.UUID`.
- Calls `Submit`, persists, publishes `VersionSubmitted` event.

### `approve_course_version`
- Fields: `VersionID uuid.UUID`, `ApprovedBy uuid.UUID`.
- Calls `ApproveWorkflow`, persists, publishes `VersionWorkflowApproved` event.

### `reject_course_version`
- Fields: `VersionID uuid.UUID`, `ApprovedBy uuid.UUID`, `Reason string`.
- Calls `RejectWorkflow`, persists, publishes `VersionWorkflowRejected` event.

## Query

### `list_pending_course_versions`
- Fields: optional `DepartmentID *uuid.UUID`.
- Returns versions where `approval_status='submitted'`.
- Department filter joins `course_types → master_courses(department_id)`.

## HTTP

| Method | Path | Role gate |
|---|---|---|
| POST | `/api/v1/curriculum/versions/{versionID}/submit` | `course_owner` |
| POST | `/api/v1/curriculum/versions/{versionID}/approve` | `dept_leader` |
| POST | `/api/v1/curriculum/versions/{versionID}/reject` | `dept_leader` |
| GET | `/api/v1/curriculum/versions/pending` | `dept_leader` |

Per `api/CLAUDE.md`, role enforcement is applied at the handler level via
`middleware.HasRole` (no business logic in handler).

## Batch Creation Block

`CreateCourseBatchCommand` gains optional `CourseVersionID *uuid.UUID`.
`create_course_batch.Handler` gains an injected
`courseversion.ReadRepository`. When `CourseVersionID != nil`, it must
resolve to a version with `approval_status='approved'`; otherwise the
handler returns `ErrCourseVersionNotApproved`.

## Tests

Unit tests for:
- `Submit/ApproveWorkflow/RejectWorkflow` happy + invalid transition paths.
- `submit/approve/reject` command handlers (mock repo, mock event bus).
- `create_course_batch` returns `ErrCourseVersionNotApproved` for non-approved
  version.

## Out of Scope

- Frontend (Flutter) wiring.
- Notification fan-out on workflow events (event already published; handlers
  can be added later).
