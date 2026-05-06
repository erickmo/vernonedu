# MasterCourse & CourseType Enhancements — Design Spec

**Date:** 2026-05-06
**Branch:** feat/mastercourse-coursetype-enhancements
**Status:** Approved

---

## Overview

Enhance MasterCourse and CourseType domains to support:
1. Department and Owner assignment on MasterCourse
2. Session range constraints on CourseType
3. Expanded price type model (5 types)
4. CourseBatch actual values validated against CourseType locked constraints

---

## Section 1: MasterCourse — Department & Owner

### Domain Changes

```go
type MasterCourse struct {
    // existing fields unchanged
    DepartmentID *uuid.UUID  // nullable — assignable after creation
    OwnerID      *uuid.UUID  // nullable — user with role course_owner
}
```

New methods:
```go
func (mc *MasterCourse) AssignDepartment(id uuid.UUID)
func (mc *MasterCourse) AssignOwner(id uuid.UUID)
```

### Rules
- Both fields nullable. MasterCourse can exist without department/owner.
- `NewMasterCourse()` does not require either field.
- No cascading effects when dept/owner changes — CourseBatches are unaffected.

### Frontend (web-dashboard)
- MasterCourse form adds 2 searchable select fields:
  - **Department** → `GET /api/v1/departments` (search by name)
  - **Course Owner** → `GET /api/v1/users?role=course_owner` (search by name)
- Both optional in UI, matching nullable domain.

---

## Section 2: CourseType — Sessions & Price Type

### Domain Changes

**Expand `PriceType` enum** (replaces `fixed | range | by_request`):

```go
var ValidPriceTypes = []string{
    "per_student",             // ActualPrice × NumStudents
    "per_batch",               // ActualPrice flat
    "per_session",             // ActualPrice × NumSessions
    "per_student_per_session", // ActualPrice × NumStudents × NumSessions
    "by_request",              // negotiated, no preset price enforced
}
```

**Add session range fields:**

```go
type CourseType struct {
    // existing fields unchanged
    MinSessions int  // locked lower bound for batch NumSessions
    MaxSessions int  // locked upper bound for batch NumSessions
}
```

### Constraint Fields (locked — batch cannot override)

| Field | Meaning |
|-------|---------|
| `NormalPrice` | Ceiling price — batch ActualPrice cannot exceed this |
| `MinPrice` | Floor price — batch ActualPrice cannot go below this |
| `MinSessions` | Min sessions batch must schedule |
| `MaxSessions` | Max sessions batch can schedule |
| `MinParticipants` | Min students required for batch |
| `MaxParticipants` | Max students allowed in batch |

### Migration note
Existing `PriceType` values mapped to new enum:
- `fixed` → `per_batch`
- `range` → `per_student`
- `by_request` → `by_request`

---

## Section 3: CourseBatch — Actual Values & Validation

### Domain Changes

```go
type CourseBatch struct {
    // existing fields unchanged

    // Copied from CourseType at creation (immutable after)
    PriceType string

    // Editable — validated against CourseType bounds
    ActualPrice     *int64  // nil if PriceType = by_request
    DiscountedPrice *int64  // optional, must be <= ActualPrice
    NumSessions     int     // must be in [MinSessions, MaxSessions]
    NumStudents     int     // must be in [MinParticipants, MaxParticipants]
}
```

### Validation (command handler `create_coursebatch` + `update_coursebatch`)

```
if PriceType != "by_request":
    ActualPrice must be in [CourseType.MinPrice, CourseType.NormalPrice]
    DiscountedPrice (if set) must be <= ActualPrice

NumSessions must be in [CourseType.MinSessions, CourseType.MaxSessions]
NumStudents must be in [CourseType.MinParticipants, CourseType.MaxParticipants]
```

### Total Price Calculation (frontend display only — not stored)

| PriceType | Formula |
|-----------|---------|
| `per_student` | ActualPrice × NumStudents |
| `per_batch` | ActualPrice |
| `per_session` | ActualPrice × NumSessions |
| `per_student_per_session` | ActualPrice × NumStudents × NumSessions |
| `by_request` | — |

---

## Section 4: Database Migration

```sql
-- master_courses
ALTER TABLE master_courses
  ADD COLUMN department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  ADD COLUMN owner_id      UUID REFERENCES users(id) ON DELETE SET NULL;

-- course_types
ALTER TABLE course_types
  ADD COLUMN min_sessions INT NOT NULL DEFAULT 1,
  ADD COLUMN max_sessions INT NOT NULL DEFAULT 1;

-- migrate existing price_type values
UPDATE course_types SET price_type = 'per_batch'   WHERE price_type = 'fixed';
UPDATE course_types SET price_type = 'per_student' WHERE price_type = 'range';
-- 'by_request' unchanged

-- course_batches
ALTER TABLE course_batches
  ADD COLUMN actual_price      BIGINT,
  ADD COLUMN discounted_price  BIGINT,
  ADD COLUMN num_sessions      INT NOT NULL DEFAULT 0,
  ADD COLUMN num_students      INT NOT NULL DEFAULT 0;
```

---

## Section 5: API Changes

### MasterCourse
`PUT /api/v1/curriculum/courses/{id}` — add to request body:
```json
{
  "departmentId": "uuid|null",
  "ownerId": "uuid|null"
}
```

`GET /api/v1/curriculum/courses/{id}` — add to response:
```json
{
  "departmentId": "uuid|null",
  "departmentName": "string|null",
  "ownerId": "uuid|null",
  "ownerName": "string|null"
}
```

### CourseType
`POST/PUT /api/v1/curriculum/courses/{courseID}/types` — add:
```json
{
  "minSessions": 8,
  "maxSessions": 16,
  "priceType": "per_student|per_batch|per_session|per_student_per_session|by_request"
}
```

### CourseBatch
`POST /api/v1/course-batches` — add:
```json
{
  "courseTypeId": "uuid",
  "actualPrice": 1500000,
  "discountedPrice": 1200000,
  "numSessions": 12,
  "numStudents": 20
}
```
Server validates all values against CourseType bounds before persisting.

---

## Section 6: Frontend UX

### MasterCourse Form
- Add searchable select: **Departemen** (clears + searches `/api/v1/departments`)
- Add searchable select: **Course Owner** (searches `/api/v1/users?role=course_owner`)

### CourseType Form
- Expand **Tipe Harga** dropdown to 5 options with labels:
  - Per Siswa, Per Batch, Per Pertemuan, Per Siswa Per Pertemuan, Nego/By Request
- Add **Min Pertemuan** + **Max Pertemuan** number inputs

### CourseBatch Form
- On CourseType select: auto-fill `ActualPrice` (preset = NormalPrice), `NumSessions` (preset = MaxSessions), `NumStudents` (preset = MaxParticipants)
- Show helper text below each field: `Min: X — Max: Y` from CourseType constraints
- Validate client-side before submit; server re-validates

---

## Out of Scope
- No changes to CourseVersion or CourseModule
- No changes to certificate, enrollment, or payment domains
- `course_owner` and `dept_leader` role assignment is handled separately by HRM/user management
