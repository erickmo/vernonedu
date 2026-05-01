# Catalog Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bring `backend/domains/catalog` to full alignment with `docs/domains/course/spec.md`, `docs/domains/module/spec.md`, `docs/domains/department/spec.md`.

**Architecture:** Single `catalog` package owns Department, Course, CourseFormatConfig, CourseBatch, Class, CourseCostTemplate, Module, ModuleVersion, ModuleAsset, BatchModuleConfig. Layered model→repo→service→handler→events. Emits `course.batch.created`, `course.batch.closed`, `course.class.facilitator_assigned`, `course.class.rescheduled`, `course.class.cancelled`. Listens to `enrollment.confirmed` (grant module access).

**Tech Stack:** Go 1.22, chi, pgx, sqlc, fx, zap, decimal, uuid.

---

## Source-of-truth

- `docs/domains/course/spec.md`, `docs/domains/module/spec.md`, `docs/domains/department/spec.md`
- `backend/migrations/000002_init_catalog.up.sql`
- `backend/sqlc/catalog.sql`

## File Structure

| File | Responsibility |
|---|---|
| `backend/domains/catalog/model.go` | Format, Mode, BatchStatus, ModuleStatus, VersionPolicy, AssetType, InstructorType, AssignedBy enums + DTOs |
| `backend/domains/catalog/repository.go` | sqlc CRUD for all 10 entities + idempotent template-copy on batch create |
| `backend/domains/catalog/service.go` | Business rules: format validation, price floor enforcement, batch state transitions, version resolution, instructor assignment |
| `backend/domains/catalog/handler.go` | HTTP routes for departments, courses, batches, classes, modules |
| `backend/domains/catalog/events.go` | Publishers + listener for `enrollment.confirmed` |
| `backend/domains/catalog/module.go` | fx wiring + route mount |

---

## Task 1: Audit existing catalog package vs specs

- [ ] **Step 1:** `grep -n "^type " backend/domains/catalog/model.go`
- [ ] **Step 2:** `grep -n "^func (s \*Service)" backend/domains/catalog/service.go`
- [ ] **Step 3:** Compare against spec entity + method lists. Write `backend/domains/catalog/GAPS.md`.
- [ ] **Step 4:** Commit gap report.

```bash
git add backend/domains/catalog/GAPS.md
git commit -m "chore(catalog): audit gaps vs spec"
```

---

## Task 2: Department CRUD

**Files:**
- Modify: `backend/domains/catalog/service.go`, `repository.go`, `handler.go`
- Create: `backend/domains/catalog/service_department_test.go`

- [ ] **Step 1: Write failing tests**

- CreateDepartment(name, leaderUserID) → returns Department; rejects empty name
- DeactivateDepartment → `is_active=false`; courses already linked remain (no cascade)
- ListActiveDepartments → only `is_active=true`

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement service methods + sqlc queries**

Add queries to `backend/sqlc/catalog.sql`:
```sql
-- name: CreateDepartment :one
INSERT INTO departments (id, name, leader_user_id, is_active, created_by, created_at)
VALUES ($1, $2, $3, true, $4, now()) RETURNING *;

-- name: ListActiveDepartments :many
SELECT * FROM departments WHERE is_active = true ORDER BY name;
```

Run `make generate`.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(catalog): department CRUD"
```

---

## Task 3: Course CRUD with min_price/base_price validation

**Files:**
- Modify: `service.go`, `repository.go`
- Create: `service_course_test.go`

- [ ] **Step 1: Write failing tests**

- CreateCourse rejects `min_price > base_price`
- CreateCourse stores `course_creator` user; only `course_creator` role allowed (validated at handler)
- UpdateCourse keeps existing batches' prices intact

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

```go
func (s *Service) CreateCourse(ctx context.Context, in CreateCourseInput) (*Course, error) {
	if in.MinPrice.GreaterThan(in.BasePrice) {
		return nil, apperrors.Validationf("min_price cannot exceed base_price")
	}
	// ... insert via repo
}
```

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(catalog): course CRUD with price validation"
```

---

## Task 4: CourseFormatConfig — unique (course, format)

**Files:**
- Modify: `service.go`, `repository.go`, migration if missing constraint
- Create: `service_format_test.go`

- [ ] **Step 1: Failing tests**

- AddFormatConfig — duplicate `(course, format)` rejected (DB constraint surfaces as unique violation → service returns 409)
- AddFormatConfig validates `min_students <= max_students` if both set
- DisableFormat → `is_enabled=false`; batch.open blocked if no format enabled

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement + ensure migration has `UNIQUE (course_id, format)`**

If migration missing, create `000008_catalog_format_unique.up.sql`:
```sql
ALTER TABLE course_format_configs ADD CONSTRAINT uq_course_format UNIQUE (course_id, format);
```

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(catalog): course format config with unique constraint"
```

---

## Task 5: CourseCostTemplate + batch inheritance

**Files:**
- Modify: `service.go`, `repository.go`
- Create: `service_costtemplate_test.go`

- [ ] **Step 1: Failing tests**

- CreateBatch copies all CourseCostTemplate items as BatchCostLineItems with `template_ref` set
- Override label/amount on batch leaves template untouched
- Mark item `is_removed=true` excludes it from cost sum (verified in finance/profit-split tests, but cataloged here that flag is exposed)
- Add new BatchCostLineItem with `template_ref=null` succeeds

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement copy-on-create in `CreateBatch`** (transactional, single SQL `INSERT ... SELECT`)

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(catalog): batch cost line item inheritance from course template"
```

---

## Task 6: CourseBatch state transitions

**Files:**
- Modify: `service.go`
- Create: `service_batch_state_test.go`

Valid transitions: `draft → open → ongoing → closed`.

- [ ] **Step 1: Failing tests**

- `OpenBatch` rejects if no CourseFormatConfig is_enabled
- `OpenBatch` enforces `price ∈ [min_price, base_price]`
- `MoveToOngoing` rejects if enrolled count < `min_students` for any active format (queries enrollment count via repo helper)
- `CloseBatch` fires `course.batch.closed` event with `{batch_id, course_id}`
- `CreateBatch` fires `course.batch.created` with `{batch_id, course_id, schedule}`

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement state-transition methods**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(catalog): course batch state transitions and events"
```

---

## Task 7: Class scheduling + instructor assignment

**Files:**
- Modify: `service.go`
- Create: `service_class_test.go`

- [ ] **Step 1: Failing tests**

- CreateClass — `location` required if mode=offline; `online_link` required if mode=online
- AssignInstructor by course_creator self → `assigned_by=course_creator_self`
- AssignInstructor by dept_leader → `assigned_by=dept_leader`, overrides previous
- AssignInstructor with non-approved facilitator rejected
- AssignInstructor with `is_facilitator=false` rejected
- RescheduleClass fires `course.class.rescheduled` with new datetimes
- CancelClass fires `course.class.cancelled`
- AssignInstructor (facilitator) fires `course.class.facilitator_assigned`

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

Verify facilitator approval status by joining to identity (or via repo query that returns enriched data) — actual cross-domain access reads from `facilitator_proposals` table.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(catalog): class scheduling and instructor assignment"
```

---

## Task 8: Module versioning

**Files:**
- Modify: `service.go`, `repository.go`
- Create: `service_module_version_test.go`

- [ ] **Step 1: Failing tests**

- CreateModule validates ordering uniqueness within course
- PublishVersion archives previous published version atomically (transaction)
- Only one `published` version per module at any time (DB partial unique index)
- Drafts never visible to students (verified at access path)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Migration if missing**

```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_module_one_published
  ON module_versions (module_id) WHERE status = 'published';
```

- [ ] **Step 4: Implement publish-atomic**

Single SQL `WITH archived AS (UPDATE module_versions SET status='archived' WHERE module_id=$1 AND status='published') UPDATE module_versions SET status='published', published_at=now(), published_by=$2 WHERE id=$3`.

- [ ] **Step 5: PASS**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(catalog): module version publish with auto-archive"
```

---

## Task 9: Version resolution per student access

**Files:**
- Modify: `service.go`
- Create: `service_version_resolve_test.go`

- [ ] **Step 1: Failing tests** for resolution rules per spec

- No BatchModuleConfig → latest published
- BatchModuleConfig auto_latest → latest published
- BatchModuleConfig locked → locked_version
- locked_version must be published version of same module — service rejects otherwise

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement `ResolveModuleVersion(batchID, moduleID)`**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(catalog): module version resolution per batch"
```

---

## Task 10: enrollment.confirmed listener — module access grant

**Files:**
- Modify: `events.go`
- Create: `events_test.go`

- [ ] **Step 1: Failing test**

```go
func TestOnEnrollmentConfirmed_GrantsAccess(t *testing.T) {
	// publish enrollment.confirmed via fakeBus
	// expect repo.GrantModuleAccess called with all active modules of batch
}
```

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement subscription**

In `events.go`, subscribe handler fetches active modules for `course_batch_id`, inserts `module_access` rows for student. (No expiration — lifetime access per spec.)

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(catalog): grant module access on enrollment.confirmed"
```

---

## Task 11: Wire HTTP routes with RBAC

**Files:**
- Modify: `handler.go`, `module.go`

- [ ] **Step 1: Mount routes**

```
POST   /departments              [admin, vernonedu_admin]
GET    /departments              [authenticated]
POST   /courses                  [course_creator, admin]
PUT    /courses/{id}             [course_creator(own), admin]
POST   /courses/{id}/format-configs  [course_creator(own), admin]
POST   /courses/{courseID}/batches   [course_creator(own), admin]
POST   /batches/{id}/open        [admin]
POST   /batches/{id}/close       [admin]
POST   /batches/{id}/classes     [admin, course_creator(own)]
POST   /classes/{id}/instructor  [dept_leader, course_creator(own)]
POST   /classes/{id}/reschedule  [admin, course_creator(own)]
POST   /classes/{id}/cancel      [admin]
POST   /modules                  [course_creator(own)]
POST   /modules/{id}/versions/{vid}/publish  [course_creator(own)]
POST   /batches/{batchID}/modules/{modID}/lock  [course_creator(own), dept_leader]
GET    /batches/{batchID}/modules               [authenticated]  # version-resolved
```

`(own)` = handler-level check that requesting user is the course_creator of the course.

- [ ] **Step 2: Implement handlers**

- [ ] **Step 3: Smoke test via curl**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(catalog): mount HTTP routes with RBAC"
```

---

## Task 12: Verify + lint

- [ ] `cd backend && go test -race ./domains/catalog/...`
- [ ] `cd backend && golangci-lint run ./domains/catalog/...`
- [ ] Remove `GAPS.md`. Commit cleanup.

---

## Verification

1. Create department, course, format config, batch (with cost template inheriting)
2. Open batch → expect price-validation enforced
3. Create class → reschedule → cancel → expect 3 events on bus
4. Publish module v1 → publish v2 → expect v1 auto-archived
5. Lock batch to v1 → student access endpoint returns v1, not v2
6. Fire `enrollment.confirmed` (manual via test bus) → expect module access rows created
