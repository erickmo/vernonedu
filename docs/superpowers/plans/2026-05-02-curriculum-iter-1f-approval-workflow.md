# Plan — Course Version Approval Workflow

**Spec:** `docs/superpowers/specs/2026-05-02-curriculum-iter-1f-approval-workflow.md`
**Branch:** `feat/curriculum-version-approval`

## Steps

1. **Migration** — `api/migrations/057_add_courseversion_approval_workflow.sql`.
2. **Domain** — extend `internal/domain/courseversion/courseversion.go`:
   - Add constants, fields, methods (`Submit`, `ApproveWorkflow`, `RejectWorkflow`).
   - Extend `WriteRepository` with `UpdateApprovalWorkflow`.
   - Extend `ReadRepository` with `ListPending`.
   - Add events to `events.go`: `VersionSubmitted`, `VersionWorkflowApproved`, `VersionWorkflowRejected`.
3. **Repo** — extend `infrastructure/database/courseversion_repository.go`:
   - Update `Save`/`Update`/`GetByID`/`ListByType`/`GetApproved` to read/write new columns.
   - Implement `UpdateApprovalWorkflow` + `ListPending` (with optional dept filter via JOIN).
4. **Commands**:
   - `internal/command/submit_courseversion/{handler.go,errors.go}`
   - `internal/command/approve_courseversion/{handler.go,errors.go}`
   - `internal/command/reject_courseversion/{handler.go,errors.go}`
5. **Query**:
   - `internal/query/list_pending_courseversions/handler.go`
6. **HTTP** — extend `internal/delivery/http/courseversion_handler.go`:
   - Add `Submit`, `Approve`, `Reject`, `ListPending` handler methods.
   - Update `RegisterCourseVersionRoutes` with role-gated routes (chi `Group` + `RequireRole`).
7. **Batch block** — modify `internal/command/create_course_batch/handler.go`:
   - Add `CourseVersionID *uuid.UUID` to command.
   - Inject `courseversion.ReadRepository`.
   - Validate approval status before save.
8. **Wiring** — `cmd/api/main.go`: register 3 commands + 1 query, update batch wiring.
9. **Tests**:
   - `internal/domain/courseversion/courseversion_test.go` — state transitions.
   - `internal/command/submit_courseversion/handler_test.go`
   - `internal/command/approve_courseversion/handler_test.go`
   - `internal/command/reject_courseversion/handler_test.go`
10. **Verify** — `go build ./...`, `go test ./internal/domain/courseversion/... ./internal/command/...`.
11. **Commit + push + PR**.
