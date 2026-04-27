# Catalog Domain — GAPS vs Spec

**Date:** 2026-04-27
**Scope:** Audit of existing `backend/domains/catalog` package against `docs/domains/{course,module,department}/spec.md`.
**Lifecycle:** Temporary — will be removed at end of Catalog Domain Implementation Plan (Task 12).

Legend: PRESENT = code matches spec; PARTIAL = exists but missing fields/rules; MISSING = not implemented.

---

## 1. Entities / Types

| Spec entity | Status | Location / Notes |
|---|---|---|
| Department | PARTIAL (wrong domain) | Lives in `identity` schema (`backend/migrations/000001_init_identity.up.sql:88`) and `backend/domains/identity/{model.go,service.go,repository.go}`. Per current spec layout (`docs/domains/department/spec.md`) it is its own bounded context, but is a peer/dependency of catalog. NOT modelled inside `backend/domains/catalog/model.go`. No Go type `Department` re-exported from catalog. Decision needed: keep in identity, or relocate. |
| Course | PRESENT | `backend/domains/catalog/model.go:54-65`; table `catalog.courses` (migration:19-30). Field `profit_split_override` present. |
| CourseFormatConfig | PARTIAL | Table `catalog.course_format_configs` (migration:35-47) with `UNIQUE (course_id, format)`. Go struct present `model.go:67-78`. NO repository methods, NO service methods, NO handler. |
| CourseBatch | PRESENT | `model.go:80-95`; table `catalog.course_batches` (migration:62-77). All spec fields incl. `batch_bulk_price`, `web_registration_open`, `registration_open_at`, `registration_close_at`. |
| Class | PRESENT (struct) | `model.go:97-112`; table `catalog.classes` (migration:82-97). Mode/instructor fields present. |
| CourseCostTemplate | PARTIAL | Table `catalog.course_cost_templates` (migration:50-58) exists. NO Go struct in `model.go`, NO repository, NO service, NO handler. |
| BatchCostLineItem (`template_ref`) | MISSING | Per spec note this is owned by Profit Split domain — NOT a catalog responsibility, but copy-on-batch-create logic must call into Profit Split. No copy logic in `service.CreateBatch` (`service.go:73-85`). |
| Module | PARTIAL | Table `catalog.modules` (migration:103-115). Go struct `CourseModule` (`model.go:114-123`) — note name divergence (`CourseModule` vs spec `Module`). Repository CreateModule + List exists. |
| ModuleVersion | PARTIAL | Table `catalog.module_versions` (migration:117-131). Struct `model.go:125-137`. NO partial unique constraint enforcing one published version per module (see §6). NO `PublishVersion` service method (auto-archive missing). |
| ModuleAsset | PARTIAL | Table `catalog.module_assets` (migration:133-147). Struct `model.go:139-151`. NO repository, NO service, NO handler. |
| BatchModuleConfig | PARTIAL | Table `catalog.batch_module_configs` (migration:149-160) with `UNIQUE (course_batch_id, module_id)`. Struct `model.go:153-162`. NO repository, NO service (`LockBatchToVersion`), NO handler. `version_policy` typed as `string` instead of typed enum constant. |
| CourseBudgetTemplateItem | OUT OF SCOPE | Table exists (migration:162-173). Owned by Budget domain per spec — fine to leave table. |

**Type-level issues:**
- `Class.InstructorType` is `string`, not typed `InstructorType` enum (`model.go:108`). Same for `AssignedBy` (`model.go:109`).
- `BatchModuleConfig.VersionPolicy` is `string`, not typed `VersionPolicy` enum (`model.go:157`).
- No Go constants for `InstructorType` / `AssignedByType` / `VersionPolicy` in `model.go` (DB enums exist).

---

## 2. Service Methods

### Department (spec §department/spec.md)
| Spec method | Status |
|---|---|
| CreateDepartment | PRESENT — but in `identity.Service` (`backend/domains/identity/service.go:385`), not catalog. |
| ListActiveDepartments | PRESENT — `identity.Service.ListDepartments` (`service.go:391`). |
| DeactivateDepartment | MISSING in identity/catalog. |

### Course
| Spec method | Status |
|---|---|
| CreateCourse | PARTIAL — exists `service.go:25-28` but no validation that `min_price <= base_price`. No format-config seeding. |
| UpdateCourse | MISSING (no `UpdateCourse` in service or repository). |

### CourseFormatConfig
| Spec method | Status |
|---|---|
| AddFormatConfig (unique on `(course, format)`) | MISSING (DB constraint exists; no Go layer). |
| DisableFormat | MISSING. |

### Batch
| Spec method | Status |
|---|---|
| CreateBatch (copies cost template → BatchCostLineItems) | PARTIAL — `service.go:73-85` creates batch row + emits event, but does NOT copy `course_cost_templates` to Profit Split's BatchCostLineItem table. Cross-domain hook missing. Also no validation that `price ∈ [min_price, base_price]`, and no validation that ≥1 format enabled. |
| OpenBatch | PARTIAL — `service.go:41-50`. Transitions `draft → open` only; does not check ≥1 format enabled (spec rule 2). |
| MoveToOngoing | MISSING (no `draft/open → ongoing` transition; spec rule 7 — guard on enrolled count vs `min_students`). |
| CloseBatch | PARTIAL — `service.go:53-70` allows close from any non-closed status (spec implies only `ongoing → closed`). Emits event ✓. |

### Class
| Spec method | Status |
|---|---|
| CreateClass (location/online_link required by mode) | PARTIAL — `service.go:98-101` writes row; no mode/location/online_link validation (spec rule 9). |
| AssignInstructor (with `assigned_by`, fires `course.class.facilitator_assigned`) | MISSING. |
| RescheduleClass (fires `course.class.rescheduled`) | MISSING. |
| CancelClass (fires `course.class.cancelled`) | MISSING. |

### Module
| Spec method | Status |
|---|---|
| CreateModule | PARTIAL — `service.go:114-118`; no `order` collision check (DB has unique idx, but no friendly error). |
| PublishVersion (atomic auto-archive prior published) | MISSING — only `CreateModuleVersion` (`service.go:126-130`) exists, always sets status=draft. No transition draft→published with auto-archive. |
| ResolveModuleVersion (per BatchModuleConfig: locked vs auto_latest) | MISSING. |

### BatchModuleConfig
| Spec method | Status |
|---|---|
| LockBatchToVersion (locked_version must be published & same module) | MISSING. |

### Cross-domain
| Listener | Status |
|---|---|
| `enrollment.confirmed` → grant module access | PARTIAL — `events.go:34-37` subscribes to `EnrollmentCompleted` (WRONG event; spec says `enrollment.confirmed` → use `events.EnrollmentConfirmed`). Handler body is empty no-op. No StudentModuleAccess table or grant path. |

---

## 3. Repository Methods

| Required | Present | Notes |
|---|---|---|
| CreateCourse / GetCourseByID / ListCoursesByDepartment | YES | `repository.go:46-99`. |
| UpdateCourse | NO | Missing. |
| CreateFormatConfig / ListFormatConfigsByCourse / DisableFormat | NO | Whole entity unimplemented in repo. |
| CreateCostTemplate / ListCostTemplatesByCourse | NO | Missing entirely. |
| CreateBatch / GetBatchByID / UpdateBatchStatus / ListBatchesByCourse | YES | `repository.go:101-170`. |
| UpdateBatchSchedule / UpdateBatchPrice | NO | Missing. |
| CreateClass / GetClassByID / ListClassesByBatch | YES | `repository.go:172-230`. |
| UpdateClassSchedule / UpdateClassInstructor / DeleteClass (cancel) | NO | Missing. |
| CreateModule / GetModuleByID / ListModulesByCourse | YES | `repository.go:232-282`. |
| UpdateModule / DeactivateModule | NO | Missing. |
| CreateModuleVersion / GetModuleVersionByID | YES | `repository.go:284-315`. |
| PublishModuleVersion (atomic archive+publish in tx) | NO | Missing. |
| GetLatestPublishedVersion(moduleID) | NO | Missing. |
| ListModuleVersionsByModule | NO | Missing. |
| CreateModuleAsset / ListAssetsByVersion | NO | Missing. |
| UpsertBatchModuleConfig / GetBatchModuleConfig / ListBatchModuleConfigsByBatch | NO | Missing. |
| CreateDepartment / ListActiveDepartments / DeactivateDepartment | N/A in catalog | Lives in identity. |

---

## 4. Handler Routes

Mounted (`module.go:21-39`):
- `GET /api/v1/courses` (list by dept)
- `POST /api/v1/courses`
- `GET /api/v1/courses/{id}`
- `POST /api/v1/batches`
- `GET /api/v1/batches`
- `GET /api/v1/batches/{id}`
- `POST /api/v1/batches/{id}/open`
- `POST /api/v1/batches/{id}/close`
- `GET /api/v1/batches/{batchID}/classes`

Missing per spec:
- `PATCH /api/v1/courses/{id}` (UpdateCourse)
- `POST /api/v1/courses/{id}/format-configs` & `PATCH .../format-configs/{id}` (AddFormatConfig, DisableFormat)
- `GET /api/v1/courses/{id}/format-configs`
- `POST /api/v1/courses/{id}/cost-templates` & list
- `POST /api/v1/batches/{id}/start` (MoveToOngoing)
- `POST /api/v1/batches/{batchID}/classes` (CreateClass)
- `PATCH /api/v1/classes/{id}/instructor` (AssignInstructor)
- `PATCH /api/v1/classes/{id}/schedule` (RescheduleClass)
- `POST /api/v1/classes/{id}/cancel`
- `POST /api/v1/courses/{id}/modules` (CreateModule)
- `GET /api/v1/courses/{id}/modules`
- `POST /api/v1/modules/{id}/versions` (CreateModuleVersion)
- `POST /api/v1/module-versions/{id}/publish` (PublishVersion)
- `POST /api/v1/module-versions/{id}/assets` (CreateModuleAsset) + list
- `PUT /api/v1/batches/{batchID}/module-configs/{moduleID}` (LockBatchToVersion)
- (Department routes already at `/api/v1/departments` in identity module — needs CreateDepartment + Deactivate.)

---

## 5. Events

### Triggers (spec)
| Event | Status |
|---|---|
| `course.batch.created` | PRESENT — emitted in `service.CreateBatch` (`service.go:81`); constant `events.BatchCreated`. Local payload `BatchCreatedPayload` (events.go:11) duplicates `internal/events/payloads.go:125` — clarify which is canonical. |
| `course.batch.closed` | PRESENT — emitted in `service.CloseBatch` (`service.go:65`). |
| `course.class.facilitator_assigned` | MISSING emit — payload struct exists in `events.go:23` but no service method publishes it. Constant `events.ClassFacilitatorAssigned` defined. Spec payload requires `batch_id` (current local struct only has `class_id` + `facilitator_id`). |
| `course.class.rescheduled` | MISSING emit — payload struct `events.go:29` minimal (only `class_id`); spec requires `batch_id, new_date, new_start_time, new_end_time`. |
| `course.class.cancelled` | MISSING emit AND missing payload struct in `events.go`. Spec payload: `{class_id, batch_id}`. |

### Listens (spec — module domain)
| Event | Status |
|---|---|
| `enrollment.confirmed` → grant module access | INCORRECT — subscribes to `EnrollmentCompleted` not `EnrollmentConfirmed` (`events.go:35`); handler is empty. |

---

## 6. Migration Coverage

| Required | Status |
|---|---|
| `UNIQUE (course_id, format)` on `course_format_configs` | PRESENT (`uq_course_format`, migration:46). |
| `UNIQUE (module_id, version_number)` on `module_versions` | PRESENT (`uq_module_version`, migration:129). |
| **Partial unique on `module_versions` WHERE status='published'** (one published per module) | MISSING — spec module rule 2. Need `CREATE UNIQUE INDEX ... ON module_versions(module_id) WHERE status='published'`. |
| `UNIQUE (course_batch_id, module_id)` on `batch_module_configs` | PRESENT (`uq_batch_module`, migration:158). |
| `UNIQUE (course_id, "order")` on `modules` | PRESENT (`uq_module_order`, migration:115). |
| CHECK `min_price <= base_price` on `courses` | MISSING — only Go-level validation needed (currently absent). DB-level CHECK recommended. |
| CHECK `price BETWEEN min_price AND base_price` on `course_batches` | MISSING — cross-row, must be enforced in service layer. |
| CHECK `(mode='offline' AND location IS NOT NULL) OR (mode='online' AND online_link IS NOT NULL)` on `classes` | MISSING. |
| CHECK `version_policy='locked' → locked_version_id IS NOT NULL` on `batch_module_configs` | MISSING. |
| CHECK `start_date <= end_date` on `course_batches` | MISSING. |
| CHECK `start_time < end_time` on `classes` | MISSING. |
| `locked_version_id` FK ON DELETE SET NULL | PRESENT (migration:154) — but spec requires the locked version to be a published version of the *same* module; only enforceable in service or trigger. |
| `BatchCostLineItem` table with `template_ref` linking back to `course_cost_templates` | OUT OF SCOPE for catalog (Profit Split owns) — confirm cross-domain plan. |
| `student_module_access` table (cross-domain listen result) | MISSING — needed for spec module Student Access section. |

---

## 7. Misc / Cross-cutting

- `service.go` has zero use of `s.log` (zap injected but never logged) — observability gap.
- No tests file under `backend/domains/catalog/` (other domains have `_test.go`). Plan must add unit tests covering service rules (price floor, format gating, publish auto-archive, version resolution).
- `CourseModule` struct name in Go vs spec `Module` — naming divergence; either rename to `Module` or document. (Risk: clash with `fx.Module` import.)
- `RegisterSubscriptions` currently subscribes to wrong event and is a no-op — must be wired to grant module access on `enrollment.confirmed`.
- Local payload structs in `events.go` partially duplicate `backend/internal/events/payloads.go`; need single source of truth.

---

## 8. Summary of Gap Categories (drives Tasks 2–11)

1. Department — clarify ownership (identity vs catalog vs new department package); add `DeactivateDepartment`.
2. Course — `UpdateCourse`, price-floor validation, full repo/service/handler for `CourseFormatConfig` and `CourseCostTemplate`.
3. Batch — price/format/min-students validations; `MoveToOngoing`; cost-template copy hook to Profit Split.
4. Class — schedule/instructor/cancel methods + mode-mode validation + correct event payloads with `batch_id`, full reschedule fields, and cancelled struct.
5. Module — `PublishVersion` atomic auto-archive (transaction) + partial unique index migration; `ResolveModuleVersion`; module asset CRUD.
6. BatchModuleConfig — `LockBatchToVersion` with referential validation.
7. Cross-domain listen — fix `enrollment.confirmed` subscription, add module access grant table + repo + handler.
8. Migration — add CHECKs (price floor, mode/location, version_policy lock requirement, date/time order) and partial unique index for published module versions.
9. Type hygiene — typed enums for `InstructorType`, `AssignedByType`, `VersionPolicy`.
10. Handler/router — add ~15 missing routes listed in §4.
11. Tests — service-layer unit tests for every rule above; integration tests for publish auto-archive transaction.
