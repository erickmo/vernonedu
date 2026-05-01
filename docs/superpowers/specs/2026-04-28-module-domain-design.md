# Design: Module Domain

**Date:** 2026-04-28
**Status:** Approved
**Scope:** New Module domain — student-facing content access, class progress tracking, refactor module entities out of catalog

---

## Overview

Extract module-related entities from the `catalog` domain into a dedicated `module` domain. Add class progress tracking (which modules were covered per Class session) and student-facing content access for enrolled students.

---

## Architecture

### Refactor: Catalog → Module

The following Go code ownership moves from `catalog` to `module`. DB tables remain in the `catalog` schema — no data migration.

| Entity | Table | Previous Owner | New Owner |
|---|---|---|---|
| CourseModule | `catalog.modules` | catalog | module |
| ModuleVersion | `catalog.module_versions` | catalog | module |
| ModuleAsset | `catalog.module_assets` | catalog | module |
| BatchModuleConfig | `catalog.batch_module_configs` | catalog | module |

`catalog` domain retains: `Course`, `CourseBatch`, `Class`, `CourseFormatConfig`, `CourseCostTemplate`.

---

## Entities

### CourseModule (existing — moved from catalog)
| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| course_id | uuid | FK → catalog.courses |
| title | string | |
| order | integer | Display order within course |
| is_active | boolean | Inactive modules hidden from students |
| created_by | uuid | FK → identity.users |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(course_id, order)`

### ModuleVersion (existing — moved from catalog)
One published version per module at a time. Publishing auto-archives previous.

| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| module_id | uuid | FK → catalog.modules |
| version_number | integer | Auto-incremented per module |
| title | string | |
| description | text | Nullable |
| status | enum | `draft`, `published`, `archived` |
| published_at | datetime | Nullable |
| published_by | uuid | Nullable; FK → identity.users |
| created_by | uuid | FK → identity.users |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(module_id, version_number)`

### ModuleAsset (existing — moved from catalog)
| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| module_version_id | uuid | FK → catalog.module_versions |
| title | string | |
| asset_type | enum | `video`, `pdf`, `document`, `link`, `image`, `other` |
| url | string | File URL or external link |
| size_bytes | bigint | Nullable; for uploaded files |
| order | integer | Display order within module |
| is_downloadable | boolean | Whether student can download |
| created_by | uuid | FK → identity.users |
| created_at | datetime | |
| updated_at | datetime | |

### BatchModuleConfig (existing — moved from catalog)
Optional per-module version policy override per batch.

| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| course_batch_id | uuid | FK → catalog.course_batches |
| module_id | uuid | FK → catalog.modules |
| version_policy | enum | `auto_latest`, `locked` |
| locked_version_id | uuid | Nullable; FK → catalog.module_versions; required if locked |
| set_by | uuid | FK → identity.users |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(course_batch_id, module_id)`

### ClassModuleCoverage (new)
Tracks which modules were covered per Class session.

| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| class_id | uuid | FK → catalog.classes |
| module_id | uuid | FK → catalog.modules |
| status | enum | `planned`, `covered` |
| covered_by | uuid | Nullable; FK → identity.users |
| covered_at | datetime | Nullable |
| is_auto_covered | boolean | True if triggered by attendance event |
| notes | string | Nullable |
| created_by | uuid | FK → identity.users |
| created_at | datetime | |
| updated_at | datetime | |

Unique: `(class_id, module_id)`

---

## New Migration

```sql
CREATE TYPE catalog.coverage_status AS ENUM ('planned', 'covered');

CREATE TABLE catalog.class_module_coverages (
  id              UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id        UUID                    NOT NULL REFERENCES catalog.classes(id) ON DELETE CASCADE,
  module_id       UUID                    NOT NULL REFERENCES catalog.modules(id) ON DELETE CASCADE,
  status          catalog.coverage_status NOT NULL DEFAULT 'planned',
  covered_by      UUID                    NULL REFERENCES identity.users(id) ON DELETE SET NULL,
  covered_at      TIMESTAMPTZ             NULL,
  is_auto_covered BOOLEAN                 NOT NULL DEFAULT FALSE,
  notes           TEXT                    NULL,
  created_by      UUID                    NOT NULL REFERENCES identity.users(id) ON DELETE RESTRICT,
  created_at      TIMESTAMPTZ             NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ             NOT NULL DEFAULT now(),
  CONSTRAINT uq_class_module UNIQUE (class_id, module_id)
);
SELECT attach_updated_at_trigger('catalog', 'class_module_coverages');
CREATE INDEX idx_class_module_coverages_class  ON catalog.class_module_coverages(class_id);
CREATE INDEX idx_class_module_coverages_module ON catalog.class_module_coverages(module_id);
```

---

## Student Access

Access granted when `enrollment.confirmed` fires. Access is **lifetime** — does not expire when batch closes.

### Version Resolution (per module per batch)
```
1. Check BatchModuleConfig for (course_batch_id, module_id)
   → policy = locked      → serve locked_version
   → policy = auto_latest → serve latest published version
   → no config            → serve latest published version (default)
```

Rules:
- Draft versions are never visible to students
- Inactive modules (`is_active = false`) are hidden from students
- Download restricted per `ModuleAsset.is_downloadable`

---

## Class Progress

### Manual Flow
Instructor plans which modules will be covered in a Class → status `planned`.
After class, instructor marks as covered → status `covered`.

### Auto Flow (attendance-triggered)
When `attendance.class_completed` event fires for a Class:
- Module domain auto-flips all `planned` entries for that class → `covered`
- Sets `is_auto_covered = true`, `covered_at = now()`
- Does NOT create new coverage entries — only flips existing `planned` ones

*Note: `attendance.class_completed` will be fired by the Attendance domain when built. Handler is defined now but inactive until Attendance domain is live.*

### Batch Progress Summary
```
total_modules   = COUNT(active modules in course)
covered_modules = COUNT(DISTINCT module_id WHERE status = 'covered') across all classes in batch
progress_pct    = covered_modules / total_modules × 100
```

---

## API Endpoints

### Module Management
| Method | Path | Roles |
|--------|------|-------|
| `POST` | `/courses/:id/modules` | admin, course_creator (own) |
| `PATCH` | `/courses/:id/modules/:module_id` | admin, course_creator (own) |
| `POST` | `/modules/:id/versions` | admin, course_creator (own) |
| `POST` | `/modules/:id/versions/:ver_id/publish` | admin, course_creator (own) |
| `POST` | `/modules/:id/versions/:ver_id/assets` | admin, course_creator (own) |
| `PATCH` | `/modules/:id/versions/:ver_id/assets/:asset_id` | admin, course_creator (own) |
| `DELETE` | `/modules/:id/versions/:ver_id/assets/:asset_id` | admin, course_creator (own) |

### Batch Config
| Method | Path | Roles |
|--------|------|-------|
| `GET` | `/batches/:id/module-configs` | admin, dept_leader, course_creator (own) |
| `PUT` | `/batches/:id/module-configs/:module_id` | admin, dept_leader, course_creator (own) |

### Class Progress
| Method | Path | Roles |
|--------|------|-------|
| `GET` | `/classes/:id/coverage` | admin, dept_leader, course_creator (own), facilitator (assigned) |
| `POST` | `/classes/:id/coverage` | admin, course_creator (own), facilitator (assigned) |
| `PATCH` | `/classes/:id/coverage/:cov_id` | admin, course_creator (own), facilitator (assigned) |
| `DELETE` | `/classes/:id/coverage/:cov_id` | admin, course_creator (own), facilitator (assigned) |
| `GET` | `/batches/:id/progress` | admin, dept_leader, course_creator (own) |

### Student Access
| Method | Path | Roles |
|--------|------|-------|
| `GET` | `/enrollments/:id/modules` | student (enrolled only) |
| `GET` | `/enrollments/:id/modules/:module_id` | student (enrolled only) |

---

## Business Rules

1. Only one ModuleVersion can have `status = published` per module at a time
2. Publishing a new version auto-archives the previous published version
3. `locked_version` in BatchModuleConfig must reference a published version of the same module
4. Students see the latest published version unless BatchModuleConfig overrides to `locked`
5. Draft versions never visible to students
6. Inactive modules hidden from all students
7. Module order is explicit — Course Creator sets sequence; `(course_id, order)` unique
8. `ClassModuleCoverage` auto-coverage only flips `planned` → `covered`; does not create new entries
9. `covered_at` and `covered_by` required when status transitions to `covered` (manual); auto-covered sets `covered_at = now()`, `covered_by = null`
10. Facilitator can only manage coverage for classes they are assigned to as instructor

---

## Cross-Domain Events

### Triggers (I fire these)
| Event | Payload | Listeners |
|---|---|---|
| — | — | — |

### Listens (I react to these)
| Event | Source | My action |
|---|---|---|
| `enrollment.confirmed` | Enrollment | Validate student has access (real-time check at request time, no materialized grant) |
| `attendance.class_completed` | Attendance | Auto-flip `planned` → `covered` for all coverage entries of that class |

---

## File Structure

```
backend/domains/module/
  model.go          ← CourseModule, ModuleVersion, ModuleAsset, BatchModuleConfig, ClassModuleCoverage
  repository.go     ← all DB queries
  service.go        ← business logic (version resolution, class progress, access check)
  handler.go        ← HTTP handlers
  module.go         ← Uber Fx module registration
  events.go         ← event type definitions + listeners
  service_integration_test.go
```

---

## Related Domains

- [course](../../domains/course/course.md)
- [enrollment](../../domains/enrollment/enrollment.md)
- [attendance](../../domains/attendance/attendance.md) *(planned)*
- [auth](../../domains/auth/auth.md)
