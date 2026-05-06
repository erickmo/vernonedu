# MasterCourse & CourseType Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add DepartmentID + OwnerID to MasterCourse, MinSessions/MaxSessions + expanded PriceType to CourseType, and ActualPrice/DiscountedPrice/NumSessions/NumStudents (validated against CourseType bounds) to CourseBatch.

**Architecture:** Extend existing domain entities in-place (Opsi A). Migration adds nullable columns to 3 tables. Command handlers, repos, HTTP handlers, and frontend forms updated in cascade. No new entities created.

**Tech Stack:** Go + sqlx + PostgreSQL (API), React 18 + TypeScript + TanStack Query (frontend)

**Spec:** `docs/superpowers/specs/2026-05-06-mastercourse-coursetype-enhancements-design.md`

---

## File Map

### API (Backend)
| File | Action |
|------|--------|
| `api/migrations/082_mastercourse_coursetype_enhancements.sql` | CREATE |
| `api/internal/domain/mastercourse/mastercourse.go` | MODIFY — add DepartmentID, OwnerID, AssignDepartment(), AssignOwner() |
| `api/internal/domain/coursetype/coursetype.go` | MODIFY — add MinSessions, MaxSessions, expand ValidPriceTypes |
| `api/internal/command/create_mastercourse/handler.go` | MODIFY — add DepartmentID, OwnerID to command |
| `api/internal/command/update_mastercourse/handler.go` | MODIFY — add DepartmentID, OwnerID to command |
| `api/internal/command/create_coursetype/handler.go` | MODIFY — add MinSessions, MaxSessions to command |
| `api/internal/command/update_coursetype/handler.go` | MODIFY — add MinSessions, MaxSessions to command |
| `api/internal/query/get_mastercourse/handler.go` | MODIFY — add DepartmentID, DepartmentName, OwnerID, OwnerName to read model |
| `api/infrastructure/database/mastercourse_repository.go` | MODIFY — add dept/owner columns to record, Save, Update, GetByID queries |
| `api/infrastructure/database/coursetype_repository.go` | MODIFY — add min/max sessions to record, Save, Update, SELECT queries |
| `api/internal/delivery/http/mastercourse_handler.go` | MODIFY — add dept/owner to request structs |
| `api/internal/delivery/http/coursetype_handler.go` | MODIFY — add min/max sessions to request structs |

### Frontend (web-dashboard)
| File | Action |
|------|--------|
| `web-dashboard/src/pages/Course/CourseFormPage.tsx` | MODIFY — add department + owner searchable selects |
| `web-dashboard/src/pages/Course/CourseDashboardPage.tsx` | MODIFY — add CourseType management tab with min/max sessions + new price type |

---

## Task 1: Database Migration

**Files:**
- Create: `api/migrations/082_mastercourse_coursetype_enhancements.sql`

- [ ] **Step 1: Create migration file**

```sql
-- +migrate Up

-- master_courses: add department and owner assignment
ALTER TABLE master_courses
  ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS owner_id      UUID REFERENCES users(id) ON DELETE SET NULL;

-- course_types: add session range constraints + migrate price_type enum
ALTER TABLE course_types
  ADD COLUMN IF NOT EXISTS min_sessions INT NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS max_sessions INT NOT NULL DEFAULT 1;

-- migrate existing price_type values to new enum
UPDATE course_types SET price_type = 'per_batch'   WHERE price_type = 'fixed';
UPDATE course_types SET price_type = 'per_student'  WHERE price_type = 'range';
-- 'by_request' unchanged

-- course_batches: add actual values (validated against CourseType bounds)
ALTER TABLE course_batches
  ADD COLUMN IF NOT EXISTS actual_price      BIGINT,
  ADD COLUMN IF NOT EXISTS discounted_price  BIGINT,
  ADD COLUMN IF NOT EXISTS num_sessions      INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS num_students      INT NOT NULL DEFAULT 0;

-- +migrate Down
ALTER TABLE master_courses DROP COLUMN IF EXISTS department_id, DROP COLUMN IF EXISTS owner_id;
ALTER TABLE course_types DROP COLUMN IF EXISTS min_sessions, DROP COLUMN IF EXISTS max_sessions;
ALTER TABLE course_batches DROP COLUMN IF EXISTS actual_price, DROP COLUMN IF EXISTS discounted_price, DROP COLUMN IF EXISTS num_sessions, DROP COLUMN IF EXISTS num_students;
```

- [ ] **Step 2: Run migration**

```bash
cd api && make migrate-up
```

Expected: `OK — 082_mastercourse_coursetype_enhancements.sql`

- [ ] **Step 3: Verify columns exist**

```bash
cd api && psql $DATABASE_URL -c "\d master_courses" | grep -E "department_id|owner_id"
cd api && psql $DATABASE_URL -c "\d course_types" | grep -E "min_sessions|max_sessions"
cd api && psql $DATABASE_URL -c "\d course_batches" | grep -E "actual_price|num_sessions"
```

Expected: all 7 new columns visible.

- [ ] **Step 4: Commit**

```bash
git add api/migrations/082_mastercourse_coursetype_enhancements.sql
git commit -m "feat(migration): add dept/owner to master_courses, sessions to course_types, batch actual values"
```

---

## Task 2: MasterCourse Domain

**Files:**
- Modify: `api/internal/domain/mastercourse/mastercourse.go`

- [ ] **Step 1: Add DepartmentID, OwnerID fields and methods**

In `mastercourse.go`, update the `MasterCourse` struct and add two methods:

```go
type MasterCourse struct {
	ID               uuid.UUID
	CourseCode       string
	CourseName       string
	Field            string
	CoreCompetencies []string
	Description      string
	Status           string
	SupportingAppUrl *string
	DepartmentID     *uuid.UUID // nullable — assignable after creation
	OwnerID          *uuid.UUID // nullable — user with role course_owner
	CreatedAt        time.Time
	UpdatedAt        time.Time
}
```

Add these two methods after `Archive()`:

```go
func (mc *MasterCourse) AssignDepartment(id *uuid.UUID) {
	mc.DepartmentID = id
	mc.UpdatedAt = time.Now()
}

func (mc *MasterCourse) AssignOwner(id *uuid.UUID) {
	mc.OwnerID = id
	mc.UpdatedAt = time.Now()
}
```

- [ ] **Step 2: Verify compile**

```bash
cd api && go build ./internal/domain/mastercourse/...
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add api/internal/domain/mastercourse/mastercourse.go
git commit -m "feat(domain): add DepartmentID, OwnerID to MasterCourse"
```

---

## Task 3: CourseType Domain

**Files:**
- Modify: `api/internal/domain/coursetype/coursetype.go`

- [ ] **Step 1: Replace ValidPriceTypes and add session fields**

Replace the existing `ValidTypes` block — find this section in `coursetype.go`:

```go
// ValidTypes adalah daftar tipe pembelajaran yang diperbolehkan dalam sistem VernonEdu.
var ValidTypes = []string{
```

The file already has `ValidTypes` for type names. We're replacing the PriceType concept (which is currently just a free string). Add `ValidPriceTypes` const + update the struct.

Add after the `ValidCertTypes` block:

```go
// ValidPriceTypes adalah daftar tipe harga yang diperbolehkan.
var ValidPriceTypes = []string{
	"per_student",             // ActualPrice × NumStudents = total
	"per_batch",               // ActualPrice flat regardless of student count
	"per_session",             // ActualPrice × NumSessions = total
	"per_student_per_session", // ActualPrice × NumStudents × NumSessions
	"by_request",              // negotiated, no preset price enforced
}
```

Add `MinSessions` and `MaxSessions` to the `CourseType` struct (after `MaxParticipants`):

```go
type CourseType struct {
	ID               uuid.UUID
	MasterCourseID   uuid.UUID
	TypeName         string
	IsActive         bool
	PriceType        string
	PriceMin         *int64
	PriceMax         *int64
	PriceCurrency    string
	PriceNotes       string
	TargetAudience   string
	ExtraDocs        []string
	CertificationType string
	ComponentFailureConfig *ComponentFailureConfig
	NormalPrice            int64
	MinPrice               int64
	MinParticipants        int
	MaxParticipants        int
	MinSessions            int // locked lower bound for batch NumSessions
	MaxSessions            int // locked upper bound for batch NumSessions
	CreatedAt              time.Time
	UpdatedAt              time.Time
}
```

- [ ] **Step 2: Update NewCourseType to accept MinSessions, MaxSessions**

Current signature:
```go
func NewCourseType(masterCourseID uuid.UUID, typeName, priceType, priceCurrency, targetAudience, certType string, extraDocs []string, failureConfig *ComponentFailureConfig, normalPrice, minPrice int64, minParticipants, maxParticipants int) (*CourseType, error) {
```

New signature (add `minSessions, maxSessions int` at end):
```go
func NewCourseType(masterCourseID uuid.UUID, typeName, priceType, priceCurrency, targetAudience, certType string, extraDocs []string, failureConfig *ComponentFailureConfig, normalPrice, minPrice int64, minParticipants, maxParticipants, minSessions, maxSessions int) (*CourseType, error) {
```

Add to the returned struct:
```go
return &CourseType{
    // ... existing fields ...
    MinParticipants:        minParticipants,
    MaxParticipants:        maxParticipants,
    MinSessions:            minSessions,
    MaxSessions:            maxSessions,
    CreatedAt:              time.Now(),
    UpdatedAt:              time.Now(),
}, nil
```

- [ ] **Step 3: Update Update() to accept MinSessions, MaxSessions**

Current signature:
```go
func (ct *CourseType) Update(targetAudience, certType string, extraDocs []string, failureConfig *ComponentFailureConfig, normalPrice, minPrice int64, minParticipants, maxParticipants int) error {
```

New:
```go
func (ct *CourseType) Update(targetAudience, certType string, extraDocs []string, failureConfig *ComponentFailureConfig, normalPrice, minPrice int64, minParticipants, maxParticipants, minSessions, maxSessions int) error {
```

Add at end of Update body (before `UpdatedAt`):
```go
ct.MinSessions = minSessions
ct.MaxSessions = maxSessions
```

- [ ] **Step 4: Verify compile**

```bash
cd api && go build ./internal/domain/coursetype/...
```

Expected: compile errors in command handlers (callers of NewCourseType/Update) — that's correct, will fix in next tasks.

- [ ] **Step 5: Commit**

```bash
git add api/internal/domain/coursetype/coursetype.go
git commit -m "feat(domain): add MinSessions/MaxSessions to CourseType, expand ValidPriceTypes"
```

---

## Task 4: MasterCourse Command Handlers

**Files:**
- Modify: `api/internal/command/create_mastercourse/handler.go`
- Modify: `api/internal/command/update_mastercourse/handler.go`

- [ ] **Step 1: Update CreateMasterCourseCommand**

In `create_mastercourse/handler.go`, add to the command struct:

```go
type CreateMasterCourseCommand struct {
	CourseCode       string   `validate:"required"`
	CourseName       string   `validate:"required,min=1"`
	Field            string   `validate:"required"`
	CoreCompetencies []string
	Description      string
	SupportingAppUrl string
	DepartmentID     *uuid.UUID
	OwnerID          *uuid.UUID
}
```

In `Handle()`, after `mc.SupportingAppUrl = &url` block, add:

```go
mc.AssignDepartment(c.DepartmentID)
mc.AssignOwner(c.OwnerID)
```

- [ ] **Step 2: Update UpdateMasterCourseCommand**

In `update_mastercourse/handler.go`, add to the command struct:

```go
type UpdateMasterCourseCommand struct {
	MasterCourseID   uuid.UUID `validate:"required"`
	CourseName       string    `validate:"required,min=1"`
	Field            string    `validate:"required"`
	CoreCompetencies []string
	Description      string
	SupportingAppUrl string
	DepartmentID     *uuid.UUID
	OwnerID          *uuid.UUID
}
```

In `Handle()`, after `mc.Update(...)` call, add:

```go
mc.AssignDepartment(c.DepartmentID)
mc.AssignOwner(c.OwnerID)
```

- [ ] **Step 3: Verify compile**

```bash
cd api && go build ./internal/command/create_mastercourse/... ./internal/command/update_mastercourse/...
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add api/internal/command/create_mastercourse/handler.go api/internal/command/update_mastercourse/handler.go
git commit -m "feat(command): add DepartmentID, OwnerID to mastercourse commands"
```

---

## Task 5: CourseType Command Handlers

**Files:**
- Modify: `api/internal/command/create_coursetype/handler.go`
- Modify: `api/internal/command/update_coursetype/handler.go`

- [ ] **Step 1: Update CreateCourseTypeCommand**

In `create_coursetype/handler.go`, add to command struct:

```go
type CreateCourseTypeCommand struct {
	MasterCourseID         uuid.UUID `validate:"required"`
	TypeName               string    `validate:"required"`
	PriceType              string
	PriceCurrency          string
	TargetAudience         string
	CertificationType      string
	ExtraDocs              []string
	ComponentFailureConfig *coursetype.ComponentFailureConfig
	NormalPrice            int64
	MinPrice               int64
	MinParticipants        int
	MaxParticipants        int
	MinSessions            int
	MaxSessions            int
}
```

Update the `NewCourseType` call in `Handle()`:

```go
ct, err := coursetype.NewCourseType(
    c.MasterCourseID, c.TypeName, c.PriceType, c.PriceCurrency,
    c.TargetAudience, c.CertificationType, c.ExtraDocs, c.ComponentFailureConfig,
    c.NormalPrice, c.MinPrice, c.MinParticipants, c.MaxParticipants,
    c.MinSessions, c.MaxSessions,
)
```

- [ ] **Step 2: Update UpdateCourseTypeCommand**

In `update_coursetype/handler.go`, add to command struct:

```go
type UpdateCourseTypeCommand struct {
	CourseTypeID           uuid.UUID `validate:"required"`
	TargetAudience         string
	CertificationType      string
	ExtraDocs              []string
	ComponentFailureConfig *coursetype.ComponentFailureConfig
	PriceType              string
	PriceMin               *int64
	PriceMax               *int64
	PriceCurrency          string
	PriceNotes             string
	NormalPrice            int64
	MinPrice               int64
	MinParticipants        int
	MaxParticipants        int
	MinSessions            int
	MaxSessions            int
}
```

Update the `ct.Update(...)` call in `Handle()`:

```go
if err := ct.Update(c.TargetAudience, c.CertificationType, c.ExtraDocs, c.ComponentFailureConfig, c.NormalPrice, c.MinPrice, c.MinParticipants, c.MaxParticipants, c.MinSessions, c.MaxSessions); err != nil {
```

- [ ] **Step 3: Verify compile**

```bash
cd api && go build ./internal/command/create_coursetype/... ./internal/command/update_coursetype/...
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add api/internal/command/create_coursetype/handler.go api/internal/command/update_coursetype/handler.go
git commit -m "feat(command): add MinSessions/MaxSessions to coursetype commands"
```

---

## Task 6: MasterCourse Repository

**Files:**
- Modify: `api/infrastructure/database/mastercourse_repository.go`

- [ ] **Step 1: Add fields to masterCourseRecord**

In the `masterCourseRecord` struct, add after `SupportingAppUrl`:

```go
type masterCourseRecord struct {
	ID               uuid.UUID  `db:"id"`
	CourseCode       string     `db:"course_code"`
	CourseName       string     `db:"course_name"`
	Field            string     `db:"field"`
	CoreCompetencies []byte     `db:"core_competencies"`
	Description      string     `db:"description"`
	Status           string     `db:"status"`
	SupportingAppUrl *string    `db:"supporting_app_url"`
	DepartmentID     *uuid.UUID `db:"department_id"`
	OwnerID          *uuid.UUID `db:"owner_id"`
	CreatedAt        time.Time  `db:"created_at"`
	UpdatedAt        time.Time  `db:"updated_at"`
}
```

- [ ] **Step 2: Update toDomain()**

In `toDomain()`, add the two new fields to the returned struct:

```go
return &mastercourse.MasterCourse{
    ID:               rec.ID,
    CourseCode:       rec.CourseCode,
    CourseName:       rec.CourseName,
    Field:            rec.Field,
    CoreCompetencies: coreCompetencies,
    Description:      rec.Description,
    Status:           rec.Status,
    SupportingAppUrl: rec.SupportingAppUrl,
    DepartmentID:     rec.DepartmentID,
    OwnerID:          rec.OwnerID,
    CreatedAt:        rec.CreatedAt,
    UpdatedAt:        rec.UpdatedAt,
}, nil
```

- [ ] **Step 3: Update Save() SQL**

Find the `Save()` INSERT query and update it:

```go
query := `
    INSERT INTO master_courses (id, course_code, course_name, field, core_competencies, description, status, supporting_app_url, department_id, owner_id, created_at, updated_at)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
`
```

Update the args to include `mc.DepartmentID, mc.OwnerID` (shift `created_at` and `updated_at` to $11, $12):

```go
_, err = r.db.ExecContext(ctx, query,
    mc.ID, mc.CourseCode, mc.CourseName, mc.Field, competenciesJSON,
    mc.Description, mc.Status, mc.SupportingAppUrl,
    mc.DepartmentID, mc.OwnerID,
    mc.CreatedAt, mc.UpdatedAt,
)
```

- [ ] **Step 4: Update Update() SQL**

Find the `Update()` method and add `department_id = $N, owner_id = $N+1` to the SET clause. Look for the existing UPDATE query and replace:

```go
query := `
    UPDATE master_courses SET
        course_name = $1, field = $2, core_competencies = $3, description = $4,
        supporting_app_url = $5, department_id = $6, owner_id = $7, updated_at = $8
    WHERE id = $9
`
_, err = r.db.ExecContext(ctx, query,
    mc.CourseName, mc.Field, competenciesJSON, mc.Description,
    mc.SupportingAppUrl, mc.DepartmentID, mc.OwnerID, mc.UpdatedAt, mc.ID,
)
```

- [ ] **Step 5: Update SELECT queries to include new columns**

Find all SELECT queries in `GetByID()`, `GetByCode()`, and `List()`. They currently select specific columns. Add `department_id, owner_id` to each SELECT:

For `GetByID()` and `GetByCode()`, the SELECT should include:
```sql
SELECT id, course_code, course_name, field, core_competencies, description, status, supporting_app_url, department_id, owner_id, created_at, updated_at
FROM master_courses WHERE id = $1
```

For `List()`, same columns addition.

- [ ] **Step 6: Verify compile**

```bash
cd api && go build ./infrastructure/database/...
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add api/infrastructure/database/mastercourse_repository.go
git commit -m "feat(repo): add dept/owner columns to mastercourse repository"
```

---

## Task 7: CourseType Repository

**Files:**
- Modify: `api/infrastructure/database/coursetype_repository.go`

- [ ] **Step 1: Add fields to courseTypeRecord**

In the `courseTypeRecord` struct, add after `MaxParticipants`:

```go
MinSessions            int        `db:"min_sessions"`
MaxSessions            int        `db:"max_sessions"`
```

- [ ] **Step 2: Update toDomain()**

Add to the returned `&coursetype.CourseType{}` struct:

```go
MinSessions:            rec.MinSessions,
MaxSessions:            rec.MaxSessions,
```

- [ ] **Step 3: Update Save() SQL**

Find the INSERT query in `Save()` and add `min_sessions, max_sessions`:

```go
INSERT INTO course_types (id, master_course_id, type_name, is_active, price_type, price_min, price_max, price_currency, price_notes, target_audience, extra_docs, certification_type, component_failure_config, normal_price, min_price, min_participants, max_participants, min_sessions, max_sessions, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)
```

Add `ct.MinSessions, ct.MaxSessions` to args (before `ct.CreatedAt`).

- [ ] **Step 4: Update Update() SQL**

Find the UPDATE query and add `min_sessions = $N, max_sessions = $N+1` to the SET clause. The new SET should include:

```sql
SET is_active = $1, price_type = $2, price_min = $3, price_max = $4, price_currency = $5,
    price_notes = $6, target_audience = $7, extra_docs = $8, certification_type = $9,
    component_failure_config = $10, normal_price = $11, min_price = $12,
    min_participants = $13, max_participants = $14, min_sessions = $15, max_sessions = $16,
    updated_at = $17
WHERE id = $18
```

Update args accordingly.

- [ ] **Step 5: Update SELECT queries**

All `SELECT` statements in `GetByID()`, `ListByMasterCourse()`, `GetByMasterCourseAndType()` — add `min_sessions, max_sessions` to the column list.

- [ ] **Step 6: Verify compile**

```bash
cd api && go build ./infrastructure/database/...
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add api/infrastructure/database/coursetype_repository.go
git commit -m "feat(repo): add min/max sessions columns to coursetype repository"
```

---

## Task 8: GetMasterCourse Query — Read Model

**Files:**
- Modify: `api/internal/query/get_mastercourse/handler.go`

- [ ] **Step 1: Update MasterCourseReadModel**

Add dept and owner fields to the read model:

```go
type MasterCourseReadModel struct {
	ID               string   `json:"id"`
	CourseCode       string   `json:"course_code"`
	CourseName       string   `json:"course_name"`
	Field            string   `json:"field"`
	CoreCompetencies []string `json:"core_competencies"`
	Description      string   `json:"description"`
	Status           string   `json:"status"`
	SupportingAppUrl *string  `json:"supporting_app_url"`
	DepartmentID     *string  `json:"department_id"`
	OwnerID          *string  `json:"owner_id"`
	CreatedAt        int64    `json:"created_at"`
	UpdatedAt        int64    `json:"updated_at"`
}
```

- [ ] **Step 2: Update toReadModel()**

```go
func toReadModel(mc *mastercourse.MasterCourse) *MasterCourseReadModel {
	var deptID, ownerID *string
	if mc.DepartmentID != nil {
		s := mc.DepartmentID.String()
		deptID = &s
	}
	if mc.OwnerID != nil {
		s := mc.OwnerID.String()
		ownerID = &s
	}
	return &MasterCourseReadModel{
		ID:               mc.ID.String(),
		CourseCode:       mc.CourseCode,
		CourseName:       mc.CourseName,
		Field:            mc.Field,
		CoreCompetencies: mc.CoreCompetencies,
		Description:      mc.Description,
		Status:           mc.Status,
		SupportingAppUrl: mc.SupportingAppUrl,
		DepartmentID:     deptID,
		OwnerID:          ownerID,
		CreatedAt:        mc.CreatedAt.Unix(),
		UpdatedAt:        mc.UpdatedAt.Unix(),
	}
}
```

- [ ] **Step 3: Verify compile**

```bash
cd api && go build ./internal/query/get_mastercourse/...
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add api/internal/query/get_mastercourse/handler.go
git commit -m "feat(query): add dept/owner to GetMasterCourse read model"
```

---

## Task 9: HTTP Handlers

**Files:**
- Modify: `api/internal/delivery/http/mastercourse_handler.go`
- Modify: `api/internal/delivery/http/coursetype_handler.go`

- [ ] **Step 1: Update mastercourse_handler.go request structs**

Add to `CreateMasterCourseRequest`:

```go
type CreateMasterCourseRequest struct {
	CourseCode       string   `json:"course_code" validate:"required"`
	CourseName       string   `json:"course_name" validate:"required,min=1"`
	Field            string   `json:"field" validate:"required"`
	CoreCompetencies []string `json:"core_competencies"`
	Description      string   `json:"description"`
	SupportingAppUrl string   `json:"supporting_app_url"`
	DepartmentID     *string  `json:"department_id"`
	OwnerID          *string  `json:"owner_id"`
}
```

Add to `UpdateMasterCourseRequest`:

```go
type UpdateMasterCourseRequest struct {
	CourseName       string   `json:"course_name" validate:"required,min=1"`
	Field            string   `json:"field" validate:"required"`
	CoreCompetencies []string `json:"core_competencies"`
	Description      string   `json:"description"`
	SupportingAppUrl string   `json:"supporting_app_url"`
	DepartmentID     *string  `json:"department_id"`
	OwnerID          *string  `json:"owner_id"`
}
```

In the `Create()` handler, parse dept/owner UUIDs and pass to command. Add this helper at the top of the Create function body (after json.Decode):

```go
var deptID *uuid.UUID
if req.DepartmentID != nil && *req.DepartmentID != "" {
    id, err := uuid.Parse(*req.DepartmentID)
    if err != nil {
        http.Error(w, `{"error":"invalid department_id"}`, http.StatusBadRequest)
        return
    }
    deptID = &id
}
var ownerID *uuid.UUID
if req.OwnerID != nil && *req.OwnerID != "" {
    id, err := uuid.Parse(*req.OwnerID)
    if err != nil {
        http.Error(w, `{"error":"invalid owner_id"}`, http.StatusBadRequest)
        return
    }
    ownerID = &id
}
```

Pass to command:

```go
cmd := &create_mastercourse.CreateMasterCourseCommand{
    // ... existing fields ...
    DepartmentID: deptID,
    OwnerID:      ownerID,
}
```

Apply same UUID parsing pattern in `Update()` handler.

- [ ] **Step 2: Update coursetype_handler.go request structs**

Add to `CreateCourseTypeRequest`:

```go
MinSessions int `json:"min_sessions"`
MaxSessions int `json:"max_sessions"`
```

Add to `UpdateCourseTypeRequest`:

```go
MinSessions int `json:"min_sessions"`
MaxSessions int `json:"max_sessions"`
```

Pass to commands in `Create()` and `Update()` handlers.

- [ ] **Step 3: Verify full API compile**

```bash
cd api && go build ./...
```

Expected: no errors.

- [ ] **Step 4: Run linter**

```bash
cd api && make lint
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add api/internal/delivery/http/mastercourse_handler.go api/internal/delivery/http/coursetype_handler.go
git commit -m "feat(http): add dept/owner to mastercourse handler, min/max sessions to coursetype handler"
```

---

## Task 10: Frontend — MasterCourse Form

**Files:**
- Modify: `web-dashboard/src/pages/Course/CourseFormPage.tsx`

This file is at `web-dashboard/src/pages/Course/CourseFormPage.tsx` (242 lines). It currently has: courseCode, courseName, field, coreCompetencies, description, supportingAppUrl. Add department + owner searchable selects.

- [ ] **Step 1: Add department and owner state + async fetch functions**

After the existing state declarations (after `setSupportingAppUrl`), add:

```tsx
const [departmentId, setDepartmentId] = useState('')
const [departmentLabel, setDepartmentLabel] = useState('')
const [ownerId, setOwnerId] = useState('')
const [ownerLabel, setOwnerLabel] = useState('')
```

Add async fetch functions before the `useQuery` hook:

```tsx
async function fetchDepartments(search: string): Promise<SelectOption[]> {
  const params = search ? `?search=${encodeURIComponent(search)}&limit=20` : '?limit=20'
  const res = await apiClient.get<any>(`/departments${params}`)
  const items: any[] = (res as any)?.items ?? res ?? []
  return items.map((d: any) => ({ value: d.id, label: d.name }))
}

async function fetchOwners(search: string): Promise<SelectOption[]> {
  const params = search
    ? `?role=course_owner&search=${encodeURIComponent(search)}&limit=20`
    : '?role=course_owner&limit=20'
  const res = await apiClient.get<any>(`/users${params}`)
  const items: any[] = (res as any)?.items ?? res ?? []
  return items.map((u: any) => ({ value: u.id, label: u.name ?? u.full_name ?? u.email }))
}
```

- [ ] **Step 2: Populate state from existing course data**

In the `useEffect` that populates form from `course`, add:

```tsx
setDepartmentId(course.department_id ?? '')
setDepartmentLabel(course.department_name ?? course.department_id ?? '')
setOwnerId(course.owner_id ?? '')
setOwnerLabel(course.owner_name ?? course.owner_id ?? '')
```

- [ ] **Step 3: Include in submit payload**

In `handleSubmit`, update the payload:

```tsx
const payload = {
  course_code: courseCode.trim(),
  course_name: courseName.trim(),
  field,
  core_competencies: coreCompetencies,
  description: description.trim(),
  supporting_app_url: supportingAppUrl.trim() || undefined,
  department_id: departmentId || null,
  owner_id: ownerId || null,
}
```

- [ ] **Step 4: Add SearchableSelect import and apiClient import**

Ensure imports include:

```tsx
import { SearchableSelect, type SelectOption } from '@/widgets/SearchableSelect/SearchableSelect'
import { apiClient } from '@/services/api.client'
```

(Check if `SearchableSelect` is already imported — it is. Check if `apiClient` is imported — add if missing.)

- [ ] **Step 5: Render department + owner selects in the form JSX**

Add after the `Field` for `supportingAppUrl` (or in a logical position in the form):

```tsx
<Field label="Departemen" error={errors.department_id}>
  <SearchableSelect
    value={departmentId}
    label={departmentLabel}
    placeholder="Cari departemen..."
    fetchOptions={fetchDepartments}
    onChange={(val, lbl) => {
      setDepartmentId(val)
      setDepartmentLabel(lbl)
    }}
  />
</Field>

<Field label="Course Owner">
  <SearchableSelect
    value={ownerId}
    label={ownerLabel}
    placeholder="Cari course owner..."
    fetchOptions={fetchOwners}
    onChange={(val, lbl) => {
      setOwnerId(val)
      setOwnerLabel(lbl)
    }}
  />
</Field>
```

- [ ] **Step 6: Verify TypeScript compile**

```bash
cd web-dashboard && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add web-dashboard/src/pages/Course/CourseFormPage.tsx
git commit -m "feat(frontend): add department and owner searchable selects to CourseFormPage"
```

---

## Task 11: Frontend — CourseType Form (min/max sessions + price type)

**Files:**
- Modify: `web-dashboard/src/pages/Course/CourseDashboardPage.tsx`

The CourseDashboardPage currently has no CourseType management UI. Add a "Tipe Kursus" tab that shows a create form with the new fields.

- [ ] **Step 1: Add courseTypeService import and state**

At the top of `CourseDashboardPage.tsx`, add import:

```tsx
import { courseTypeService } from '@/services/course-type.service'
import { apiClient } from '@/services/api.client'
```

Add state for CourseType create modal:

```tsx
const [showTypeForm, setShowTypeForm] = useState(false)
const [typeFormData, setTypeFormData] = useState({
  type_name: '',
  normal_price: 0,
  min_price: 0,
  min_participants: 1,
  max_participants: 30,
  min_sessions: 1,
  max_sessions: 12,
  price_type: 'per_student',
  target_audience: '',
  certification_type: '',
})
```

- [ ] **Step 2: Fetch existing course types**

Add a query for course types (after existing queries):

```tsx
const { data: courseTypes = [], refetch: refetchTypes } = useQuery({
  queryKey: ['course-types', courseId],
  queryFn: async () => {
    const data = await apiClient.get<any>(`/curriculum/courses/${courseId}/types`)
    return (data as any).items ?? (data as any).data ?? data ?? []
  },
})
```

- [ ] **Step 3: Add submit handler for new CourseType**

```tsx
async function handleCreateType(e: React.FormEvent) {
  e.preventDefault()
  try {
    await apiClient.post(`/curriculum/courses/${courseId}/types`, typeFormData)
    setShowTypeForm(false)
    refetchTypes()
  } catch (err) {
    alert('Gagal membuat tipe kursus')
  }
}
```

- [ ] **Step 4: Add PRICE_TYPE_OPTIONS constant**

```tsx
const PRICE_TYPE_OPTIONS = [
  { value: 'per_student',             label: 'Per Siswa' },
  { value: 'per_batch',               label: 'Per Batch' },
  { value: 'per_session',             label: 'Per Pertemuan' },
  { value: 'per_student_per_session', label: 'Per Siswa Per Pertemuan' },
  { value: 'by_request',              label: 'Nego / By Request' },
]
```

- [ ] **Step 5: Add "Tipe Kursus" tab content**

Add `courseTypesTab` variable before the `return` statement:

```tsx
const courseTypesTab = (
  <div>
    <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 'var(--space-3)' }}>
      <button
        onClick={() => setShowTypeForm(v => !v)}
        style={{
          padding: '6px 16px', borderRadius: 'var(--radius-md)',
          background: 'var(--color-primary)', color: '#fff', border: 'none', cursor: 'pointer',
          fontSize: 'var(--font-sm)', fontWeight: 600,
        }}
      >
        {showTypeForm ? 'Batal' : '+ Tambah Tipe'}
      </button>
    </div>

    {showTypeForm && (
      <form onSubmit={handleCreateType} style={{
        padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
        marginBottom: 'var(--space-4)', display: 'grid', gap: 'var(--space-3)',
      }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-3)' }}>
          <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
            Tipe Kursus *
            <select
              value={typeFormData.type_name}
              onChange={e => setTypeFormData(p => ({ ...p, type_name: e.target.value }))}
              required
              style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
            >
              <option value="">Pilih tipe...</option>
              <option value="regular">Regular</option>
              <option value="private">Private</option>
              <option value="company_training">Inhouse Training</option>
              <option value="collab_school">Kolaborasi Sekolah</option>
              <option value="collab_university">Kolaborasi Universitas</option>
              <option value="program_karir">Program Karir</option>
            </select>
          </label>

          <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
            Tipe Harga *
            <select
              value={typeFormData.price_type}
              onChange={e => setTypeFormData(p => ({ ...p, price_type: e.target.value }))}
              style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
            >
              {PRICE_TYPE_OPTIONS.map(o => (
                <option key={o.value} value={o.value}>{o.label}</option>
              ))}
            </select>
          </label>

          <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
            Harga Normal (IDR)
            <input
              type="number" min={0}
              value={typeFormData.normal_price}
              onChange={e => setTypeFormData(p => ({ ...p, normal_price: Number(e.target.value) }))}
              style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
            />
          </label>

          <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
            Harga Minimum (IDR)
            <input
              type="number" min={0}
              value={typeFormData.min_price}
              onChange={e => setTypeFormData(p => ({ ...p, min_price: Number(e.target.value) }))}
              style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
            />
          </label>

          <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
            Min Peserta
            <input
              type="number" min={1}
              value={typeFormData.min_participants}
              onChange={e => setTypeFormData(p => ({ ...p, min_participants: Number(e.target.value) }))}
              style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
            />
          </label>

          <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
            Max Peserta
            <input
              type="number" min={1}
              value={typeFormData.max_participants}
              onChange={e => setTypeFormData(p => ({ ...p, max_participants: Number(e.target.value) }))}
              style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
            />
          </label>

          <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
            Min Pertemuan
            <input
              type="number" min={1}
              value={typeFormData.min_sessions}
              onChange={e => setTypeFormData(p => ({ ...p, min_sessions: Number(e.target.value) }))}
              style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
            />
          </label>

          <label style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>
            Max Pertemuan
            <input
              type="number" min={1}
              value={typeFormData.max_sessions}
              onChange={e => setTypeFormData(p => ({ ...p, max_sessions: Number(e.target.value) }))}
              style={{ display: 'block', width: '100%', marginTop: 4, padding: '8px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)' }}
            />
          </label>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <button type="submit" style={{
            padding: '8px 20px', borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary)', color: '#fff', border: 'none',
            cursor: 'pointer', fontWeight: 600,
          }}>
            Simpan Tipe
          </button>
        </div>
      </form>
    )}

    {courseTypes.length === 0 && !showTypeForm ? (
      <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
        Belum ada tipe kursus. Tambahkan tipe pertama.
      </div>
    ) : (
      <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
        {courseTypes.map((t: any) => (
          <div key={t.id} style={{
            padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            display: 'grid', gridTemplateColumns: '1fr auto', alignItems: 'center',
          }}>
            <div>
              <div style={{ fontWeight: 600 }}>{t.type_name}</div>
              <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginTop: 2 }}>
                {PRICE_TYPE_OPTIONS.find(o => o.value === t.price_type)?.label ?? t.price_type}
                {' · '}Rp {(t.normal_price ?? 0).toLocaleString('id-ID')}
                {' · '}{t.min_sessions}–{t.max_sessions} pertemuan
                {' · '}{t.min_participants}–{t.max_participants} peserta
              </div>
            </div>
            <span style={{
              padding: '2px 10px', borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
              background: t.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
              color: t.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
            }}>
              {t.is_active ? 'Aktif' : 'Nonaktif'}
            </span>
          </div>
        ))}
      </div>
    )}
  </div>
)
```

- [ ] **Step 6: Register the new tab**

In the `tabs` array passed to `DetailPageTemplate`, add:

```tsx
{ id: 'types', label: 'Tipe Kursus', icon: <BookOpen size={14} />, content: courseTypesTab },
```

Add it before the `versions` tab.

- [ ] **Step 7: Add useState import if not already present**

Verify `useState` is imported from 'react'. If not:

```tsx
import { useState } from 'react'
```

- [ ] **Step 8: Verify TypeScript compile**

```bash
cd web-dashboard && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 9: Commit**

```bash
git add web-dashboard/src/pages/Course/CourseDashboardPage.tsx
git commit -m "feat(frontend): add CourseType management tab with sessions and price type"
```

---

## Task 12: CourseBatch Domain + Command + Repo + HTTP

**Files:**
- Modify: `api/internal/domain/coursebatch/coursebatch.go`
- Modify: `api/internal/command/create_course_batch/handler.go`
- Modify: `api/internal/command/update_course_batch/handler.go`
- Modify: `api/infrastructure/database/course_batch_repository.go`
- Modify: `api/internal/delivery/http/course_batch_handler.go`

- [ ] **Step 1: Add fields to CourseBatch domain entity**

In `api/internal/domain/coursebatch/coursebatch.go`, add to `CourseBatch` struct (after `Status`):

```go
type CourseBatch struct {
	// ... existing fields ...
	CourseTypeID    *uuid.UUID
	PriceType       string // copied from CourseType at creation
	ActualPrice     *int64 // nil if PriceType = by_request
	DiscountedPrice *int64 // optional, must be <= ActualPrice
	NumSessions     int    // must be in [CourseType.MinSessions, CourseType.MaxSessions]
	NumStudents     int    // must be in [CourseType.MinParticipants, CourseType.MaxParticipants]
}
```

- [ ] **Step 2: Add validation errors**

Add to the `var (` errors block:

```go
ErrActualPriceTooLow    = errors.New("actual price below CourseType minimum price")
ErrActualPriceTooHigh   = errors.New("actual price above CourseType normal price")
ErrDiscountedPriceTooHigh = errors.New("discounted price must be <= actual price")
ErrNumSessionsOutOfRange  = errors.New("num_sessions out of CourseType range")
ErrNumStudentsOutOfRange  = errors.New("num_students out of CourseType range")
```

- [ ] **Step 3: Update CreateCourseBatchCommand**

In `api/internal/command/create_course_batch/handler.go`, add to command struct:

```go
type CreateCourseBatchCommand struct {
	// ... existing fields ...
	CourseTypeID    *uuid.UUID
	PriceType       string
	ActualPrice     *int64
	DiscountedPrice *int64
	NumSessions     int
	NumStudents     int
	// CourseType bounds for validation (fetched by handler)
	CTMinPrice       int64
	CTNormalPrice    int64
	CTMinSessions    int
	CTMaxSessions    int
	CTMinParticipants int
	CTMaxParticipants int
}
```

In `Handle()`, add validation before `coursebatch.NewCourseBatch(...)` or before `Save()`:

```go
// Validate actual values against CourseType bounds
if c.PriceType != "by_request" && c.ActualPrice != nil {
    if *c.ActualPrice < c.CTMinPrice {
        return coursebatch.ErrActualPriceTooLow
    }
    if *c.ActualPrice > c.CTNormalPrice {
        return coursebatch.ErrActualPriceTooHigh
    }
    if c.DiscountedPrice != nil && *c.DiscountedPrice > *c.ActualPrice {
        return coursebatch.ErrDiscountedPriceTooHigh
    }
}
if c.CourseTypeID != nil {
    if c.NumSessions < c.CTMinSessions || c.NumSessions > c.CTMaxSessions {
        return coursebatch.ErrNumSessionsOutOfRange
    }
    if c.NumStudents < c.CTMinParticipants || c.NumStudents > c.CTMaxParticipants {
        return coursebatch.ErrNumStudentsOutOfRange
    }
}
```

After creating/saving the entity, set new fields:
```go
cb.CourseTypeID    = c.CourseTypeID
cb.PriceType       = c.PriceType
cb.ActualPrice     = c.ActualPrice
cb.DiscountedPrice = c.DiscountedPrice
cb.NumSessions     = c.NumSessions
cb.NumStudents     = c.NumStudents
```

- [ ] **Step 4: Update course_batch_repository.go**

Find the `courseBatchRecord` struct in `api/infrastructure/database/course_batch_repository.go` and add:

```go
CourseTypeID    *uuid.UUID `db:"course_type_id"`
PriceType       string     `db:"price_type_batch"`  // use alias if price_type column name conflicts
ActualPrice     *int64     `db:"actual_price"`
DiscountedPrice *int64     `db:"discounted_price"`
NumSessions     int        `db:"num_sessions"`
NumStudents     int        `db:"num_students"`
```

Update `toDomain()` to map new fields. Update `Save()` INSERT SQL to include the 6 new columns. Update `Update()` SQL if num_sessions/num_students should be editable. Update all SELECT queries to include the new columns.

- [ ] **Step 5: Update HTTP handler request structs**

In `api/internal/delivery/http/course_batch_handler.go`, add to `CreateCourseBatchRequest`:

```go
CourseTypeID     string `json:"course_type_id"`
ActualPrice      *int64 `json:"actual_price"`
DiscountedPrice  *int64 `json:"discounted_price"`
NumSessions      int    `json:"num_sessions"`
NumStudents      int    `json:"num_students"`
```

In `Create()` handler, fetch CourseType to get bounds before dispatching command:

```go
// If course_type_id provided, fetch CourseType bounds
var (
    ctMinPrice, ctNormalPrice int64
    ctMinSessions, ctMaxSessions, ctMinP, ctMaxP int
    courseTypeID *uuid.UUID
    priceType    string
)
if req.CourseTypeID != "" {
    ctID, err := uuid.Parse(req.CourseTypeID)
    if err != nil {
        http.Error(w, `{"error":"invalid course_type_id"}`, http.StatusBadRequest)
        return
    }
    courseTypeID = &ctID
    // fetch CourseType from repo (inject CourseTypeReadRepository into handler)
    ct, err := h.courseTypeRepo.GetByID(r.Context(), ctID)
    if err != nil {
        http.Error(w, `{"error":"course type not found"}`, http.StatusBadRequest)
        return
    }
    ctMinPrice    = ct.MinPrice
    ctNormalPrice = ct.NormalPrice
    ctMinSessions = ct.MinSessions
    ctMaxSessions = ct.MaxSessions
    ctMinP        = ct.MinParticipants
    ctMaxP        = ct.MaxParticipants
    priceType     = ct.PriceType
}
```

Pass all values to command. The `CourseBatchHandler` struct needs `courseTypeRepo coursetype.ReadRepository` injected via constructor.

- [ ] **Step 6: Verify compile**

```bash
cd api && go build ./...
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add \
  api/internal/domain/coursebatch/coursebatch.go \
  api/internal/command/create_course_batch/handler.go \
  api/internal/command/update_course_batch/handler.go \
  api/infrastructure/database/course_batch_repository.go \
  api/internal/delivery/http/course_batch_handler.go
git commit -m "feat(batch): add CourseType-validated actual price, sessions, students to CourseBatch"
```

---

## Task 13: Integration Smoke Test (renamed from 12)

- [ ] **Step 1: Start API**

```bash
cd api && make dev
```

Expected: API starts on port 8081, no migration errors.

- [ ] **Step 2: Start frontend**

```bash
cd web-dashboard && npm run dev
```

Expected: dev server starts on port 3001.

- [ ] **Step 3: Test MasterCourse create with dept + owner**

```bash
curl -X POST http://localhost:8081/api/v1/curriculum/courses \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "course_code": "TEST-001",
    "course_name": "Test Course",
    "field": "Teknologi",
    "department_id": "<valid-dept-uuid>",
    "owner_id": "<valid-user-uuid>"
  }'
```

Expected: 201 with course ID.

- [ ] **Step 4: Test CourseType create with sessions**

```bash
curl -X POST http://localhost:8081/api/v1/curriculum/courses/<courseId>/types \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "type_name": "regular",
    "price_type": "per_student",
    "normal_price": 2000000,
    "min_price": 1500000,
    "min_participants": 5,
    "max_participants": 20,
    "min_sessions": 8,
    "max_sessions": 16
  }'
```

Expected: 201.

- [ ] **Step 5: Test GET returns dept/owner + sessions**

```bash
curl http://localhost:8081/api/v1/curriculum/courses/<courseId> \
  -H "Authorization: Bearer <token>"
```

Expected: response includes `department_id`, `owner_id`.

- [ ] **Step 6: Commit if all passing**

```bash
git add -p
git commit -m "test(smoke): mastercourse dept/owner + coursetype sessions verified"
```
