# Catalog & Module API Contract Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add missing HTTP routes in the Catalog and Module domains so all frontend API hooks in `frontend/src/lib/api/catalog.ts` resolve to actual backend endpoints.

**Architecture:** The backend (`backend/`) already has service/repository methods for all needed operations. Only handlers and route registrations are missing. No new DB migrations needed. Changes are in two domains: `catalog` (4 new routes) and `module` (5 new routes/aliases). Identity domain mismatches (POST /students, POST /departments) are deferred to a follow-up plan.

**Tech Stack:** Go 1.23, Chi v5, pgx/v5, Uber FX, testify (integration build tag)

---

## Route Gap Summary

| Frontend calls | Backend has | Fix |
|---|---|---|
| `PATCH /api/v1/courses/{id}` | Nothing | Add UpdateCourse repo+service+handler+route |
| `GET /api/v1/courses/{id}/batches` | `GET /api/v1/batches?course_id=` | Add path-param handler+route |
| `PATCH /api/v1/batches/{id}/status` | `POST /batches/{id}/open`, `/close` | Add UpdateBatchStatus service+handler+route |
| `POST /api/v1/classes` | Nothing | Add CreateClass handler+route |
| `GET /api/v1/courses/{id}/modules` | Nothing (only POST exists) | Add ListModules handler+route |
| `GET /api/v1/modules/{id}/versions` | Nothing | Add ListVersionsByModule service+handler+route |
| `GET /api/v1/module-versions/{id}/assets` | `/modules/{id}/versions/{ver_id}/assets` | Add simplified handler+route |
| `POST /api/v1/module-versions/{id}/publish` | `/modules/{id}/versions/{ver_id}/publish` | Add simplified handler+route |
| `POST /api/v1/module-assets` | `/modules/{id}/versions/{ver_id}/assets` | Add body-param handler+route |

---

## File Map

**Catalog domain:**
- Modify: `backend/domains/catalog/repository.go` — add `UpdateCourse` to interface + impl
- Modify: `backend/domains/catalog/service.go` — add `UpdateCourse`, `UpdateBatchStatus`
- Modify: `backend/domains/catalog/handler.go` — add 4 handlers
- Modify: `backend/domains/catalog/module.go` — add 4 routes
- Modify: `backend/domains/catalog/handler_test.go` — add test cases

**Module domain:**
- Modify: `backend/domains/module/service.go` — add `ListVersionsByModule`
- Modify: `backend/domains/module/handler.go` — add 5 handlers
- Modify: `backend/domains/module/module.go` — add 5 routes

---

## Task 1: Catalog — UpdateCourse

**Files:**
- Modify: `backend/domains/catalog/repository.go`
- Modify: `backend/domains/catalog/service.go`
- Modify: `backend/domains/catalog/handler.go`
- Modify: `backend/domains/catalog/module.go`
- Modify: `backend/domains/catalog/handler_test.go`

- [ ] **Step 1: Write the failing handler test**

Add to `backend/domains/catalog/handler_test.go` (inside the `buildCatalogRouter` function, add the new route, then add the test):

```go
// In buildCatalogRouter, add:
r.Patch("/api/v1/courses/{id}", h.UpdateCourse)

// New test:
func TestCatalog_UpdateCourse(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	s := seedIdentity(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	course := &catalog.Course{
		Name:            "Original Name",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1000000),
		MinPrice:        decimal.NewFromInt(800000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))

	router := buildCatalogRouter(svc, s.creatorID)
	body := `{"name":"Updated Name","description":"New desc","duration_days":14,"status":"active"}`
	req := httptest.NewRequest(http.MethodPatch, "/api/v1/courses/"+course.ID.String(), strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
	var updated catalog.Course
	require.NoError(t, json.NewDecoder(w.Body).Decode(&updated))
	require.Equal(t, "Updated Name", updated.Name)
	require.Equal(t, "New desc", updated.Description)
	require.Equal(t, 14, updated.DurationDays)
}
```

Add missing imports to `handler_test.go`:
```go
import (
    "encoding/json"
    "strings"
    // existing imports...
)
```

- [ ] **Step 2: Run test to verify it fails**

```bash
go test -tags integration -run TestCatalog_UpdateCourse ./backend/domains/catalog/ -v
```

Expected: FAIL — `h.UpdateCourse` is undefined

- [ ] **Step 3: Add UpdateCourse to the Repository interface**

In `backend/domains/catalog/repository.go`, add to the `Repository` interface (after `CreateCourse`):

```go
UpdateCourse(ctx context.Context, c *Course) error
```

Add the implementation (after the `GetCourseByID` implementation):

```go
func (r *repository) UpdateCourse(ctx context.Context, c *Course) error {
	query := `
		UPDATE catalog.courses
		SET name = $1, description = $2, duration_days = $3, status = $4, updated_at = NOW()
		WHERE id = $5`
	ct, err := r.pool.Exec(ctx, query, c.Name, c.Description, c.DurationDays, c.Status, c.ID)
	if err != nil {
		return fmt.Errorf("catalog.UpdateCourse: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}
```

- [ ] **Step 4: Add UpdateCourse to the Service**

In `backend/domains/catalog/service.go`, add after `GetCourse`:

```go
func (s *Service) UpdateCourse(ctx context.Context, c *Course) error {
	return s.repo.UpdateCourse(ctx, c)
}
```

- [ ] **Step 5: Add UpdateCourse handler**

In `backend/domains/catalog/handler.go`, add after `GetCourse`:

```go
func (h *Handler) UpdateCourse(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	var course Course
	if err := json.NewDecoder(r.Body).Decode(&course); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	course.ID = id
	if err := h.svc.UpdateCourse(r.Context(), &course); err != nil {
		apperrors.Render(w, err)
		return
	}
	got, err := h.svc.GetCourse(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(got)
}
```

- [ ] **Step 6: Register the route**

In `backend/domains/catalog/module.go`, inside `RegisterRoutes` (in the JWT-protected group), add:

```go
r.Patch("/api/v1/courses/{id}", h.UpdateCourse)
```

- [ ] **Step 7: Run test to verify it passes**

```bash
go test -tags integration -run TestCatalog_UpdateCourse ./backend/domains/catalog/ -v
```

Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add backend/domains/catalog/repository.go backend/domains/catalog/service.go \
        backend/domains/catalog/handler.go backend/domains/catalog/module.go \
        backend/domains/catalog/handler_test.go
git commit -m "feat(catalog): add PATCH /courses/{id} — UpdateCourse handler"
```

---

## Task 2: Catalog — ListBatchesByCourse Path Param (GET /api/v1/courses/{id}/batches)

**Files:**
- Modify: `backend/domains/catalog/handler.go`
- Modify: `backend/domains/catalog/module.go`
- Modify: `backend/domains/catalog/handler_test.go`

- [ ] **Step 1: Write the failing test**

Add to `buildCatalogRouter` in `handler_test.go`:
```go
r.Get("/api/v1/courses/{id}/batches", h.ListBatchesByCourseID)
```

Add test:
```go
func TestCatalog_ListBatchesByCourseID(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	s := seedIdentity(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	course := &catalog.Course{
		Name:            "Course X",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1000000),
		MinPrice:        decimal.NewFromInt(800000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))

	batch := &catalog.CourseBatch{
		CourseID:  course.ID,
		Label:     "Batch A",
		StartDate: time.Now(),
		EndDate:   time.Now().AddDate(0, 1, 0),
		Price:     decimal.NewFromInt(1200000),
		CreatedBy: s.creatorID,
	}
	require.NoError(t, svc.CreateBatch(ctx, batch))

	router := buildCatalogRouter(svc, s.creatorID)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/courses/"+course.ID.String()+"/batches", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
	var result []*catalog.CourseBatch
	require.NoError(t, json.NewDecoder(w.Body).Decode(&result))
	require.Len(t, result, 1)
	require.Equal(t, batch.ID, result[0].ID)
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
go test -tags integration -run TestCatalog_ListBatchesByCourseID ./backend/domains/catalog/ -v
```

Expected: FAIL — `h.ListBatchesByCourseID` undefined

- [ ] **Step 3: Add ListBatchesByCourseID handler**

In `backend/domains/catalog/handler.go`, add after `ListBatches`:

```go
func (h *Handler) ListBatchesByCourseID(w http.ResponseWriter, r *http.Request) {
	courseID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	batches, err := h.svc.ListBatchesByCourse(r.Context(), courseID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(batches)
}
```

- [ ] **Step 4: Register the route**

In `backend/domains/catalog/module.go`, add in the JWT group:

```go
r.Get("/api/v1/courses/{id}/batches", h.ListBatchesByCourseID)
```

- [ ] **Step 5: Run test to verify it passes**

```bash
go test -tags integration -run TestCatalog_ListBatchesByCourseID ./backend/domains/catalog/ -v
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add backend/domains/catalog/handler.go backend/domains/catalog/module.go \
        backend/domains/catalog/handler_test.go
git commit -m "feat(catalog): add GET /courses/{id}/batches — path-param batch list"
```

---

## Task 3: Catalog — UpdateBatchStatus (PATCH /api/v1/batches/{id}/status)

**Files:**
- Modify: `backend/domains/catalog/service.go`
- Modify: `backend/domains/catalog/handler.go`
- Modify: `backend/domains/catalog/module.go`
- Modify: `backend/domains/catalog/handler_test.go`

- [ ] **Step 1: Write the failing test**

Add to `buildCatalogRouter`:
```go
r.Patch("/api/v1/batches/{id}/status", h.PatchBatchStatus)
```

Add test:
```go
func TestCatalog_PatchBatchStatus(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	s := seedIdentity(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	course := &catalog.Course{
		Name:            "Course Y",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1000000),
		MinPrice:        decimal.NewFromInt(800000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))

	batch := &catalog.CourseBatch{
		CourseID:  course.ID,
		Label:     "Batch B",
		StartDate: time.Now(),
		EndDate:   time.Now().AddDate(0, 1, 0),
		Price:     decimal.NewFromInt(1200000),
		CreatedBy: s.creatorID,
	}
	require.NoError(t, svc.CreateBatch(ctx, batch))

	router := buildCatalogRouter(svc, s.creatorID)
	body := `{"status":"open"}`
	req := httptest.NewRequest(http.MethodPatch, "/api/v1/batches/"+batch.ID.String()+"/status", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
	var result catalog.CourseBatch
	require.NoError(t, json.NewDecoder(w.Body).Decode(&result))
	require.Equal(t, catalog.BatchStatus("open"), result.Status)
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
go test -tags integration -run TestCatalog_PatchBatchStatus ./backend/domains/catalog/ -v
```

Expected: FAIL — `h.PatchBatchStatus` undefined

- [ ] **Step 3: Add UpdateBatchStatus to Service**

In `backend/domains/catalog/service.go`, add after `CloseBatch`:

```go
func (s *Service) UpdateBatchStatus(ctx context.Context, batchID uuid.UUID, status BatchStatus) error {
	return s.repo.UpdateBatchStatus(ctx, batchID, status)
}
```

- [ ] **Step 4: Add PatchBatchStatus handler**

In `backend/domains/catalog/handler.go`, add after `CloseBatch`:

```go
func (h *Handler) PatchBatchStatus(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid batch id"))
		return
	}
	var req struct {
		Status BatchStatus `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if req.Status == "" {
		apperrors.Render(w, apperrors.Validationf("status is required"))
		return
	}
	if err := h.svc.UpdateBatchStatus(r.Context(), id, req.Status); err != nil {
		apperrors.Render(w, err)
		return
	}
	batch, err := h.svc.GetBatch(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(batch)
}
```

- [ ] **Step 5: Register the route**

In `backend/domains/catalog/module.go`, add in JWT group:

```go
r.Patch("/api/v1/batches/{id}/status", h.PatchBatchStatus)
```

- [ ] **Step 6: Run test to verify it passes**

```bash
go test -tags integration -run TestCatalog_PatchBatchStatus ./backend/domains/catalog/ -v
```

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add backend/domains/catalog/service.go backend/domains/catalog/handler.go \
        backend/domains/catalog/module.go backend/domains/catalog/handler_test.go
git commit -m "feat(catalog): add PATCH /batches/{id}/status handler"
```

---

## Task 4: Catalog — CreateClass (POST /api/v1/classes)

**Files:**
- Modify: `backend/domains/catalog/handler.go`
- Modify: `backend/domains/catalog/module.go`
- Modify: `backend/domains/catalog/handler_test.go`

- [ ] **Step 1: Write the failing test**

Add to `buildCatalogRouter`:
```go
r.Post("/api/v1/classes", h.CreateClass)
```

Add test (add `time` import if not present):
```go
func TestCatalog_CreateClass(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	s := seedIdentity(t, pool)
	svc := newService(t, pool)
	ctx := context.Background()

	course := &catalog.Course{
		Name:            "Course Z",
		DepartmentID:    s.deptID,
		CourseCreatorID: s.creatorID,
		BasePrice:       decimal.NewFromInt(1000000),
		MinPrice:        decimal.NewFromInt(800000),
		CreatedBy:       s.creatorID,
	}
	require.NoError(t, svc.CreateCourse(ctx, course))

	batch := &catalog.CourseBatch{
		CourseID:  course.ID,
		Label:     "Batch C",
		StartDate: time.Now(),
		EndDate:   time.Now().AddDate(0, 1, 0),
		Price:     decimal.NewFromInt(1200000),
		CreatedBy: s.creatorID,
	}
	require.NoError(t, svc.CreateBatch(ctx, batch))

	router := buildCatalogRouter(svc, s.creatorID)
	body := fmt.Sprintf(`{
		"course_batch_id": %q,
		"session_date": "2026-05-01",
		"start_time": "09:00",
		"end_time": "12:00",
		"mode": "online",
		"instructor_id": %q,
		"instructor_type": "course_creator",
		"assigned_by": "admin"
	}`, batch.ID, s.creatorID)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/classes", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
	var cl catalog.Class
	require.NoError(t, json.NewDecoder(w.Body).Decode(&cl))
	require.Equal(t, batch.ID, cl.CourseBatchID)
}
```

Add `"fmt"` to imports.

- [ ] **Step 2: Run test to verify it fails**

```bash
go test -tags integration -run TestCatalog_CreateClass ./backend/domains/catalog/ -v
```

Expected: FAIL — `h.CreateClass` undefined

- [ ] **Step 3: Add CreateClass handler**

In `backend/domains/catalog/handler.go`, add after `ListClasses`:

```go
func (h *Handler) CreateClass(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	var cl Class
	if err := json.NewDecoder(r.Body).Decode(&cl); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	if err := h.svc.CreateClass(r.Context(), &cl); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(cl)
}
```

- [ ] **Step 4: Register the route**

In `backend/domains/catalog/module.go`, add in JWT group:

```go
r.Post("/api/v1/classes", h.CreateClass)
```

- [ ] **Step 5: Run test to verify it passes**

```bash
go test -tags integration -run TestCatalog_CreateClass ./backend/domains/catalog/ -v
```

Expected: PASS

- [ ] **Step 6: Run all catalog tests**

```bash
go test -tags integration ./backend/domains/catalog/ -v
```

Expected: all PASS

- [ ] **Step 7: Commit**

```bash
git add backend/domains/catalog/handler.go backend/domains/catalog/module.go \
        backend/domains/catalog/handler_test.go
git commit -m "feat(catalog): add POST /classes handler"
```

---

## Task 5: Module — ListModules (GET /api/v1/courses/{id}/modules)

**Files:**
- Modify: `backend/domains/module/handler.go`
- Modify: `backend/domains/module/module.go`

The service already has `ListModules(ctx, courseID)` → `[]*CourseModule, error`. Just need the handler.

- [ ] **Step 1: Add ListModules handler**

In `backend/domains/module/handler.go`, add after `UpdateModule`:

```go
func (h *Handler) ListModules(w http.ResponseWriter, r *http.Request) {
	courseID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid course id"))
		return
	}
	modules, err := h.svc.ListModules(r.Context(), courseID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, modules)
}
```

- [ ] **Step 2: Register the route**

In `backend/domains/module/module.go`, inside `registerModuleRoutes`, add:

```go
view := mw.RequireRole(roleAdmin, roleDeptLeader, roleCourseCreator, roleFacilitator, roleStudent)
r.With(view).Get("/api/v1/courses/{id}/modules", h.ListModules)
```

- [ ] **Step 3: Build to verify no compile errors**

```bash
go build ./backend/...
```

Expected: success (no output)

- [ ] **Step 4: Commit**

```bash
git add backend/domains/module/handler.go backend/domains/module/module.go
git commit -m "feat(module): add GET /courses/{id}/modules handler"
```

---

## Task 6: Module — ListVersionsByModule (GET /api/v1/modules/{id}/versions)

**Files:**
- Modify: `backend/domains/module/service.go`
- Modify: `backend/domains/module/handler.go`
- Modify: `backend/domains/module/module.go`

The repository already has `ListVersionsByModule(ctx, moduleID) ([]*ModuleVersion, error)`.

- [ ] **Step 1: Add ListVersionsByModule to Service**

In `backend/domains/module/service.go`, add after `GetModuleVersion`:

```go
func (s *Service) ListVersionsByModule(ctx context.Context, moduleID uuid.UUID) ([]*ModuleVersion, error) {
	return s.repo.ListVersionsByModule(ctx, moduleID)
}
```

- [ ] **Step 2: Add ListVersions handler**

In `backend/domains/module/handler.go`, add after `CreateVersion`:

```go
func (h *Handler) ListVersions(w http.ResponseWriter, r *http.Request) {
	moduleID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid module id"))
		return
	}
	versions, err := h.svc.ListVersionsByModule(r.Context(), moduleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, versions)
}
```

- [ ] **Step 3: Register the route**

In `backend/domains/module/module.go`, inside `registerModuleRoutes`, add alongside the existing module routes:

```go
r.With(view).Get("/api/v1/modules/{id}/versions", h.ListVersions)
```

(Use the same `view` role defined in Step 2 of Task 5, or define it within `registerModuleRoutes` as shown):

```go
view := mw.RequireRole(roleAdmin, roleDeptLeader, roleCourseCreator, roleFacilitator, roleStudent)
r.With(view).Get("/api/v1/modules/{id}/versions", h.ListVersions)
```

- [ ] **Step 4: Build to verify no compile errors**

```bash
go build ./backend/...
```

Expected: success

- [ ] **Step 5: Commit**

```bash
git add backend/domains/module/service.go backend/domains/module/handler.go \
        backend/domains/module/module.go
git commit -m "feat(module): add GET /modules/{id}/versions and service.ListVersionsByModule"
```

---

## Task 7: Module — Simplified Asset & Publish Routes

**Files:**
- Modify: `backend/domains/module/handler.go`
- Modify: `backend/domains/module/module.go`

Three new simplified-path handlers:
- `GET /api/v1/module-versions/{id}/assets` — ListAssets by version ID (service already has `ListAssets`)
- `POST /api/v1/module-versions/{id}/publish` — PublishVersion by version ID only
- `POST /api/v1/module-assets` — CreateAsset with version_id in body

- [ ] **Step 1: Add ListAssetsByVersion handler**

In `backend/domains/module/handler.go`, add after `DeleteAsset`:

```go
func (h *Handler) ListAssetsByVersion(w http.ResponseWriter, r *http.Request) {
	verID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid version id"))
		return
	}
	assets, err := h.svc.ListAssets(r.Context(), verID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, assets)
}
```

- [ ] **Step 2: Add PublishVersionByVersionID handler**

In `backend/domains/module/handler.go`, add after `ListAssetsByVersion`:

```go
func (h *Handler) PublishVersionByVersionID(w http.ResponseWriter, r *http.Request) {
	verID, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid version id"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	ver, err := h.svc.GetModuleVersion(r.Context(), verID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	m, err := h.svc.GetModule(r.Context(), ver.ModuleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.PublishVersion(r.Context(), ver.ModuleID, verID, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
```

- [ ] **Step 3: Add CreateAssetByVersionID handler**

In `backend/domains/module/handler.go`, add after `PublishVersionByVersionID`:

```go
func (h *Handler) CreateAssetByVersionID(w http.ResponseWriter, r *http.Request) {
	var req struct {
		VersionID      uuid.UUID `json:"version_id"`
		Title          string    `json:"title"`
		AssetType      AssetType `json:"asset_type"`
		URL            string    `json:"url"`
		SizeBytes      *int64    `json:"size_bytes"`
		Order          int       `json:"order"`
		IsDownloadable bool      `json:"is_downloadable"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	ver, err := h.svc.GetModuleVersion(r.Context(), req.VersionID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	m, err := h.svc.GetModule(r.Context(), ver.ModuleID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if err := h.svc.AssertCourseOwner(r.Context(), m.CourseID, uc.ID, uc.Role); err != nil {
		apperrors.Render(w, err)
		return
	}
	a, err := h.svc.CreateAsset(r.Context(), req.VersionID, req.Title, req.AssetType, req.URL, req.SizeBytes, req.Order, req.IsDownloadable, uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, a)
}
```

- [ ] **Step 4: Register the three new routes**

In `backend/domains/module/module.go`, add a new `registerVersionRoutes` helper (call it from `RegisterRoutes`):

```go
func registerVersionRoutes(r chi.Router, h *Handler) {
	view   := mw.RequireRole(roleAdmin, roleDeptLeader, roleCourseCreator, roleFacilitator, roleStudent)
	manage := mw.RequireRole(roleAdmin, roleCourseCreator)

	r.With(view).Get("/api/v1/module-versions/{id}/assets", h.ListAssetsByVersion)
	r.With(manage).Post("/api/v1/module-versions/{id}/publish", h.PublishVersionByVersionID)
	r.With(manage).Post("/api/v1/module-assets", h.CreateAssetByVersionID)
}
```

Call `registerVersionRoutes(r, h)` inside `RegisterRoutes` (in the JWT group).

- [ ] **Step 5: Build to verify no compile errors**

```bash
go build ./backend/...
```

Expected: success

- [ ] **Step 6: Run all module tests**

```bash
go test -tags integration ./backend/domains/module/ -v
```

Expected: all PASS (no regressions)

- [ ] **Step 7: Commit**

```bash
git add backend/domains/module/handler.go backend/domains/module/module.go
git commit -m "feat(module): add simplified asset/publish routes (module-versions/{id}/*)"
```

---

## Task 8: Final Verification

- [ ] **Step 1: Build entire backend**

```bash
go build ./backend/...
```

Expected: success

- [ ] **Step 2: Run all integration tests**

```bash
go test -tags integration ./backend/... -v 2>&1 | tail -30
```

Expected: all PASS

- [ ] **Step 3: Verify route list**

```bash
grep -r "r\.\(Get\|Post\|Put\|Patch\|Delete\)" backend/domains/catalog/module.go backend/domains/module/module.go | grep "/api/v1/"
```

Verify these routes now exist:
- `PATCH /api/v1/courses/{id}`
- `GET /api/v1/courses/{id}/batches`
- `PATCH /api/v1/batches/{id}/status`
- `POST /api/v1/classes`
- `GET /api/v1/courses/{id}/modules`
- `GET /api/v1/modules/{id}/versions`
- `GET /api/v1/module-versions/{id}/assets`
- `POST /api/v1/module-versions/{id}/publish`
- `POST /api/v1/module-assets`

- [ ] **Step 4: Final commit if any remaining changes**

```bash
git status
```

If clean, no commit needed.
