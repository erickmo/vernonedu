# Budget Domain — Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix six confirmed bugs and gaps in the budget domain: wrong role constant, zero-UUID `CreatedBy` on auto-copied batch items, missing role enforcement on template/batch routes, missing GET-single endpoints, missing `ON DELETE SET NULL` on `template_ref_id`, and missing `updated_at` on `BudgetRealization`.

**Architecture:** All fixes stay within the budget domain and one catalog domain touch (event payload). DB changes ship as a single migration file `000016_budget_fixes`. Tests follow the existing `//go:build integration` pattern using a real Postgres instance at `localhost:5433`.

**Tech Stack:** Go 1.22+, Chi router, Uber FX, pgx/v5, testify/require, `net/http/httptest` for HTTP-layer assertions.

**Spec:** `docs/superpowers/specs/2026-04-27-budget-domain-review-design.md`

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `backend/migrations/000016_budget_fixes.up.sql` | Create | `ON DELETE SET NULL` + `updated_at` on realizations |
| `backend/migrations/000016_budget_fixes.down.sql` | Create | Reverse migration |
| `backend/domains/budget/model.go` | Modify | Add `UpdatedAt` to `BudgetRealization` |
| `backend/domains/budget/repository.go` | Modify | Include `updated_at` in realization scan/insert/update |
| `backend/domains/catalog/events.go` | Modify | Add `ActorID uuid.UUID` to `BatchCreatedPayload` |
| `backend/domains/catalog/service.go` | Modify | Set `ActorID: b.CreatedBy` when publishing `BatchCreated` |
| `backend/domains/budget/events.go` | Modify | Add `ActorID` to `batchCreatedPayload`; pass to `OnBatchCreated` |
| `backend/domains/budget/service.go` | Modify | `OnBatchCreated` takes `actorID`; sets `CreatedBy` on items |
| `backend/domains/budget/handler.go` | Modify | Remove `roleAdmin` const + all inline role checks; add `GetTemplateItem`, `GetBatchItem`, `GetRealization` handlers |
| `backend/domains/budget/module.go` | Modify | Add role consts; restructure routes with `mw.RequireRole`; add GET-single routes |
| `backend/internal/middleware/auth.go` | Modify | Add exported `WithUserContext` helper for test injection |
| `backend/domains/budget/service_integration_test.go` | Create | Integration tests for `OnBatchCreated` and overridable-lock |
| `backend/domains/budget/handler_test.go` | Create | HTTP-level tests: role enforcement + GET single endpoints |

---

### Task 1: Write failing integration test for `OnBatchCreated`

This test will fail because `CreatedBy` is currently zero UUID.

**Files:**
- Create: `backend/domains/budget/service_integration_test.go`

- [ ] **Step 1: Create the test file**

```go
//go:build integration

package budget_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/budget"
)

const defaultTestDBURL = "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable"

func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DB_URL")
	if url == "" {
		url = defaultTestDBURL
	}
	pool, err := pgxpool.New(context.Background(), url)
	require.NoError(t, err)
	require.NoError(t, pool.Ping(context.Background()))
	return pool
}

func resetSchemas(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			budget.realizations,
			budget.batch_items,
			budget.template_items,
			catalog.classes,
			catalog.course_batches,
			catalog.courses,
			identity.departments,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func newService(t *testing.T, pool *pgxpool.Pool) *budget.Service {
	t.Helper()
	repo := budget.NewRepository(pool)
	return budget.NewService(repo, zap.NewNop())
}

func seedCourseAndTemplates(t *testing.T, pool *pgxpool.Pool) (courseID uuid.UUID, actorID uuid.UUID) {
	t.Helper()
	ctx := context.Background()

	actorID = uuid.New()
	_, err := pool.Exec(ctx,
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1, $2, 'x', 'vernonedu_admin')`,
		actorID, actorID.String()+"@test.local")
	require.NoError(t, err)

	deptID := uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO identity.departments (id, name) VALUES ($1, 'Test Dept')`, deptID)
	require.NoError(t, err)

	courseID = uuid.New()
	_, err = pool.Exec(ctx,
		`INSERT INTO catalog.courses (id, name, department_id, course_creator_id, base_price, min_price, created_by)
		 VALUES ($1, 'Test Course', $2, $3, 0, 0, $3)`,
		courseID, deptID, actorID)
	require.NoError(t, err)

	// Seed two template items
	for i, label := range []string{"Item A", "Item B"} {
		_, err = pool.Exec(ctx,
			`INSERT INTO budget.template_items (id, course_id, label, preset_amount, overridable)
			 VALUES ($1, $2, $3, $4, true)`,
			uuid.New(), courseID, label, float64((i+1)*100))
		require.NoError(t, err)
	}
	return courseID, actorID
}

func TestOnBatchCreated_SetsCreatedByToActor(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	courseID, actorID := seedCourseAndTemplates(t, pool)
	batchID := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO catalog.course_batches (id, course_id, label, start_date, end_date, price, status, created_by)
		 VALUES ($1, $2, 'Batch 1', now(), now() + interval '30 days', 0, 'draft', $3)`,
		batchID, courseID, actorID)
	require.NoError(t, err)

	svc := newService(t, pool)
	err = svc.OnBatchCreated(context.Background(), batchID, courseID, actorID)
	require.NoError(t, err)

	repo := budget.NewRepository(pool)
	items, err := repo.ListBatchItems(context.Background(), batchID)
	require.NoError(t, err)
	require.Len(t, items, 2)

	for _, item := range items {
		require.Equal(t, actorID, item.CreatedBy,
			"CreatedBy must equal the actor who created the batch, got zero UUID")
	}
}

func TestUpdateBatchItem_OverridableLock(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	courseID, actorID := seedCourseAndTemplates(t, pool)
	batchID := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO catalog.course_batches (id, course_id, label, start_date, end_date, price, status, created_by)
		 VALUES ($1, $2, 'Batch 1', now(), now() + interval '30 days', 0, 'draft', $3)`,
		batchID, courseID, actorID)
	require.NoError(t, err)

	// Seed a non-overridable batch item directly
	itemID := uuid.New()
	_, err = pool.Exec(context.Background(),
		`INSERT INTO budget.batch_items (id, course_batch_id, label, planned_amount, overridable, created_by)
		 VALUES ($1, $2, 'Fixed Cost', 500, false, $3)`,
		itemID, batchID, actorID)
	require.NoError(t, err)

	svc := newService(t, pool)

	// Attempt to change planned_amount on a non-overridable item → must error
	err = svc.UpdateBatchItem(context.Background(), &budget.BatchBudgetItem{
		ID:            itemID,
		CourseBatchID: batchID,
		Label:         "Fixed Cost",
		PlannedAmount: 999, // changed
		Overridable:   false,
		CreatedBy:     actorID,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	})
	require.Error(t, err)
	require.Contains(t, err.Error(), "planned_amount is locked")

	// Same amount → must succeed
	err = svc.UpdateBatchItem(context.Background(), &budget.BatchBudgetItem{
		ID:            itemID,
		CourseBatchID: batchID,
		Label:         "Fixed Cost Renamed",
		PlannedAmount: 500, // unchanged
		Overridable:   false,
		CreatedBy:     actorID,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	})
	require.NoError(t, err)
}
```

- [ ] **Step 2: Run test — verify it fails on `OnBatchCreated` test**

```bash
cd backend && go test -tags=integration -run TestOnBatchCreated_SetsCreatedByToActor ./domains/budget/ -v
```

Expected output: FAIL — `CreatedBy must equal the actor... got zero UUID` (or similar assertion failure because `item.CreatedBy == uuid.Nil`).

---

### Task 2: DB Migration — `ON DELETE SET NULL` + `updated_at`

**Files:**
- Create: `backend/migrations/000016_budget_fixes.up.sql`
- Create: `backend/migrations/000016_budget_fixes.down.sql`

- [ ] **Step 1: Create up migration**

```sql
-- backend/migrations/000016_budget_fixes.up.sql

-- Fix 1: ON DELETE SET NULL for template_ref_id
ALTER TABLE budget.batch_items
    DROP CONSTRAINT IF EXISTS batch_items_template_ref_id_fkey,
    ADD CONSTRAINT batch_items_template_ref_id_fkey
        FOREIGN KEY (template_ref_id)
        REFERENCES budget.template_items(id)
        ON DELETE SET NULL;

-- Fix 2: Add updated_at to realizations
ALTER TABLE budget.realizations
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

SELECT attach_updated_at_trigger('budget', 'realizations');
```

- [ ] **Step 2: Create down migration**

```sql
-- backend/migrations/000016_budget_fixes.down.sql

DROP TRIGGER IF EXISTS set_updated_at ON budget.realizations;
ALTER TABLE budget.realizations DROP COLUMN IF EXISTS updated_at;

ALTER TABLE budget.batch_items
    DROP CONSTRAINT IF EXISTS batch_items_template_ref_id_fkey,
    ADD CONSTRAINT batch_items_template_ref_id_fkey
        FOREIGN KEY (template_ref_id)
        REFERENCES budget.template_items(id);
```

- [ ] **Step 3: Apply migration**

```bash
# From project root — check Makefile for exact migrate command
make migrate-up
# or: migrate -path backend/migrations -database "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable" up
```

Expected: migration applies with no errors.

---

### Task 3: Update `BudgetRealization` model + repository

**Files:**
- Modify: `backend/domains/budget/model.go`
- Modify: `backend/domains/budget/repository.go`

- [ ] **Step 1: Add `UpdatedAt` to `BudgetRealization` in `model.go`**

Find:
```go
type BudgetRealization struct {
	ID                 uuid.UUID  `json:"id"`
	BatchBudgetItemID  uuid.UUID  `json:"batch_budget_item_id"`
	ClassID            *uuid.UUID `json:"class_id"`
	ActualAmount       float64    `json:"actual_amount"`
	Description        string     `json:"description"`
	SpentAt            time.Time  `json:"spent_at"`
	ProofURL           *string    `json:"proof_url"`
	RecordedBy         uuid.UUID  `json:"recorded_by"`
	CreatedAt          time.Time  `json:"created_at"`
}
```

Replace with:
```go
type BudgetRealization struct {
	ID                 uuid.UUID  `json:"id"`
	BatchBudgetItemID  uuid.UUID  `json:"batch_budget_item_id"`
	ClassID            *uuid.UUID `json:"class_id"`
	ActualAmount       float64    `json:"actual_amount"`
	Description        string     `json:"description"`
	SpentAt            time.Time  `json:"spent_at"`
	ProofURL           *string    `json:"proof_url"`
	RecordedBy         uuid.UUID  `json:"recorded_by"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}
```

- [ ] **Step 2: Update `CreateRealization` in `repository.go`**

Find:
```go
func (r *pgRepository) CreateRealization(ctx context.Context, item *BudgetRealization) error {
	const q = `
		INSERT INTO budget.realizations
			(id, batch_budget_item_id, class_id, actual_amount, description, spent_at, proof_url, recorded_by, created_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`
	_, err := r.db.Exec(ctx, q,
		item.ID, item.BatchBudgetItemID, item.ClassID, item.ActualAmount,
		item.Description, item.SpentAt, item.ProofURL, item.RecordedBy, item.CreatedAt)
	return err
}
```

Replace with:
```go
func (r *pgRepository) CreateRealization(ctx context.Context, item *BudgetRealization) error {
	const q = `
		INSERT INTO budget.realizations
			(id, batch_budget_item_id, class_id, actual_amount, description, spent_at, proof_url, recorded_by, created_at, updated_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,now())`
	_, err := r.db.Exec(ctx, q,
		item.ID, item.BatchBudgetItemID, item.ClassID, item.ActualAmount,
		item.Description, item.SpentAt, item.ProofURL, item.RecordedBy, item.CreatedAt)
	return err
}
```

- [ ] **Step 3: Update `GetRealization` scan in `repository.go`**

Find:
```go
func (r *pgRepository) GetRealization(ctx context.Context, id uuid.UUID) (*BudgetRealization, error) {
	const q = `
		SELECT id, batch_budget_item_id, class_id, actual_amount, description, spent_at, proof_url, recorded_by, created_at
		FROM budget.realizations WHERE id=$1`
	item := &BudgetRealization{}
	err := r.db.QueryRow(ctx, q, id).Scan(
		&item.ID, &item.BatchBudgetItemID, &item.ClassID, &item.ActualAmount,
		&item.Description, &item.SpentAt, &item.ProofURL, &item.RecordedBy, &item.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperrors.ErrNotFound
	}
	return item, err
}
```

Replace with:
```go
func (r *pgRepository) GetRealization(ctx context.Context, id uuid.UUID) (*BudgetRealization, error) {
	const q = `
		SELECT id, batch_budget_item_id, class_id, actual_amount, description, spent_at, proof_url, recorded_by, created_at, updated_at
		FROM budget.realizations WHERE id=$1`
	item := &BudgetRealization{}
	err := r.db.QueryRow(ctx, q, id).Scan(
		&item.ID, &item.BatchBudgetItemID, &item.ClassID, &item.ActualAmount,
		&item.Description, &item.SpentAt, &item.ProofURL, &item.RecordedBy,
		&item.CreatedAt, &item.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperrors.ErrNotFound
	}
	return item, err
}
```

- [ ] **Step 4: Update `ListRealizations` scan in `repository.go`**

Find `scanRealizations`:
```go
func scanRealizations(rows pgx.Rows) ([]*BudgetRealization, error) {
	var items []*BudgetRealization
	for rows.Next() {
		item := &BudgetRealization{}
		if err := rows.Scan(
			&item.ID, &item.BatchBudgetItemID, &item.ClassID, &item.ActualAmount,
			&item.Description, &item.SpentAt, &item.ProofURL, &item.RecordedBy, &item.CreatedAt,
		); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}
```

Update the SELECT in `ListRealizations` to include `updated_at`, and update the scan:
```go
func (r *pgRepository) ListRealizations(ctx context.Context, batchItemID uuid.UUID) ([]*BudgetRealization, error) {
	const q = `
		SELECT id, batch_budget_item_id, class_id, actual_amount, description, spent_at, proof_url, recorded_by, created_at, updated_at
		FROM budget.realizations WHERE batch_budget_item_id=$1 ORDER BY spent_at ASC`
	rows, err := r.db.Query(ctx, q, batchItemID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanRealizations(rows)
}

func scanRealizations(rows pgx.Rows) ([]*BudgetRealization, error) {
	var items []*BudgetRealization
	for rows.Next() {
		item := &BudgetRealization{}
		if err := rows.Scan(
			&item.ID, &item.BatchBudgetItemID, &item.ClassID, &item.ActualAmount,
			&item.Description, &item.SpentAt, &item.ProofURL, &item.RecordedBy,
			&item.CreatedAt, &item.UpdatedAt,
		); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}
```

- [ ] **Step 5: Build to catch any compile errors**

```bash
cd backend && go build ./...
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add backend/migrations/000016_budget_fixes.up.sql \
        backend/migrations/000016_budget_fixes.down.sql \
        backend/domains/budget/model.go \
        backend/domains/budget/repository.go
git commit -m "fix(budget): add updated_at to realizations; ON DELETE SET NULL for template_ref_id"
```

---

### Task 4: Fix `OnBatchCreated` — add `actor_id` to event payload

**Files:**
- Modify: `backend/domains/catalog/events.go`
- Modify: `backend/domains/catalog/service.go`
- Modify: `backend/domains/budget/events.go`
- Modify: `backend/domains/budget/service.go`

- [ ] **Step 1: Add `ActorID` to `catalog.BatchCreatedPayload`**

In `backend/domains/catalog/events.go`, find:
```go
type BatchCreatedPayload struct {
	BatchID  uuid.UUID `json:"batch_id"`
	CourseID uuid.UUID `json:"course_id"`
}
```

Replace with:
```go
type BatchCreatedPayload struct {
	BatchID  uuid.UUID `json:"batch_id"`
	CourseID uuid.UUID `json:"course_id"`
	ActorID  uuid.UUID `json:"actor_id"`
}
```

- [ ] **Step 2: Set `ActorID` when publishing in `catalog/service.go`**

In `backend/domains/catalog/service.go`, find:
```go
_ = s.bus.Publish(ctx, events.Event{
    Type:    events.BatchCreated,
    Payload: BatchCreatedPayload{BatchID: b.ID, CourseID: b.CourseID},
})
```

Replace with:
```go
_ = s.bus.Publish(ctx, events.Event{
    Type:    events.BatchCreated,
    Payload: BatchCreatedPayload{BatchID: b.ID, CourseID: b.CourseID, ActorID: b.CreatedBy},
})
```

- [ ] **Step 3: Add `ActorID` to `budget.batchCreatedPayload`**

In `backend/domains/budget/events.go`, find:
```go
type batchCreatedPayload struct {
	BatchID  uuid.UUID `json:"batch_id"`
	CourseID uuid.UUID `json:"course_id"`
}
```

Replace with:
```go
type batchCreatedPayload struct {
	BatchID  uuid.UUID `json:"batch_id"`
	CourseID uuid.UUID `json:"course_id"`
	ActorID  uuid.UUID `json:"actor_id"`
}
```

- [ ] **Step 4: Pass `ActorID` to `OnBatchCreated` in the event handler**

In `backend/domains/budget/events.go`, find:
```go
func handleBatchCreated(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		payload, err := decodeBatchCreatedPayload(e.Payload)
		if err != nil {
			svc.log.Error("budget: failed to decode BatchCreated payload", zap.Error(err))
			return err
		}
		return svc.OnBatchCreated(ctx, payload.BatchID, payload.CourseID)
	}
}
```

Replace with:
```go
func handleBatchCreated(svc *Service) events.HandlerFunc {
	return func(ctx context.Context, e events.Event) error {
		payload, err := decodeBatchCreatedPayload(e.Payload)
		if err != nil {
			svc.log.Error("budget: failed to decode BatchCreated payload", zap.Error(err))
			return err
		}
		return svc.OnBatchCreated(ctx, payload.BatchID, payload.CourseID, payload.ActorID)
	}
}
```

- [ ] **Step 5: Update `OnBatchCreated` signature + set `CreatedBy`**

In `backend/domains/budget/service.go`, find:
```go
func (s *Service) OnBatchCreated(ctx context.Context, batchID uuid.UUID, courseID uuid.UUID) error {
	templates, err := s.repo.ListTemplateItems(ctx, courseID)
	if err != nil {
		return err
	}
	for _, tmpl := range templates {
		ref := tmpl.ID
		item := &BatchBudgetItem{
			CourseBatchID: batchID,
			TemplateRefID: &ref,
			Label:         tmpl.Label,
			Category:      tmpl.Category,
			PlannedAmount: tmpl.PresetAmount,
			Overridable:   tmpl.Overridable,
		}
```

Replace with:
```go
func (s *Service) OnBatchCreated(ctx context.Context, batchID uuid.UUID, courseID uuid.UUID, actorID uuid.UUID) error {
	templates, err := s.repo.ListTemplateItems(ctx, courseID)
	if err != nil {
		return err
	}
	for _, tmpl := range templates {
		ref := tmpl.ID
		item := &BatchBudgetItem{
			CourseBatchID: batchID,
			TemplateRefID: &ref,
			Label:         tmpl.Label,
			Category:      tmpl.Category,
			PlannedAmount: tmpl.PresetAmount,
			Overridable:   tmpl.Overridable,
			CreatedBy:     actorID,
		}
```

- [ ] **Step 6: Build to verify compilation**

```bash
cd backend && go build ./...
```

Expected: no errors.

- [ ] **Step 7: Run the failing test from Task 1 — verify it now passes**

```bash
cd backend && go test -tags=integration -run TestOnBatchCreated_SetsCreatedByToActor ./domains/budget/ -v
```

Expected: PASS.

- [ ] **Step 8: Run the overridable-lock test**

```bash
cd backend && go test -tags=integration -run TestUpdateBatchItem_OverridableLock ./domains/budget/ -v
```

Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add backend/domains/catalog/events.go \
        backend/domains/catalog/service.go \
        backend/domains/budget/events.go \
        backend/domains/budget/service.go \
        backend/domains/budget/service_integration_test.go
git commit -m "fix(budget): pass actor_id in BatchCreated payload; fix zero-UUID CreatedBy in OnBatchCreated"
```

---

### Task 5: Fix role constant + move auth enforcement to route middleware

**Files:**
- Modify: `backend/domains/budget/handler.go`
- Modify: `backend/domains/budget/module.go`

- [ ] **Step 1: Remove `roleAdmin` const and inline role checks from `handler.go`**

Delete this line from `handler.go`:
```go
const roleAdmin = "admin"
```

Remove the role-check block from `CreateRealization` (lines that check `uc.Role != roleAdmin`):
```go
// DELETE these lines from CreateRealization:
if uc.Role != roleAdmin {
    apperrors.Render(w, apperrors.ErrForbidden)
    return
}
```

Remove the same block from `UpdateRealization` and `DeleteRealization`.

After removing, `CreateRealization`, `UpdateRealization`, `DeleteRealization` should only check `uc == nil` (unauthorized), not role — role is enforced by middleware at the route level.

- [ ] **Step 2: Add role constants and restructure routes in `module.go`**

Replace the entire `module.go` content with:

```go
package budget

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

const (
	roleVernonAdmin  = "vernonedu_admin"
	roleCourseCreator = "course_creator"
)

// Module wires budget domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts all budget HTTP routes under JWT auth.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)
	manageTemplate := mw.RequireRole(roleCourseCreator, roleVernonAdmin)
	manageBatch    := mw.RequireRole(roleCourseCreator, roleVernonAdmin)
	manageRealization := mw.RequireRole(roleVernonAdmin)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		// Course budget templates — read: any auth; write: course_creator or vernonedu_admin
		r.Get("/api/v1/courses/{course_id}/budget-templates", h.ListTemplateItems)
		r.Get("/api/v1/courses/{course_id}/budget-templates/{id}", h.GetTemplateItem)
		r.With(manageTemplate).Post("/api/v1/courses/{course_id}/budget-templates", h.CreateTemplateItem)
		r.With(manageTemplate).Put("/api/v1/courses/{course_id}/budget-templates/{id}", h.UpdateTemplateItem)
		r.With(manageTemplate).Delete("/api/v1/courses/{course_id}/budget-templates/{id}", h.DeleteTemplateItem)

		// Batch budget items — read: any auth; write: course_creator or vernonedu_admin
		r.Get("/api/v1/batches/{batch_id}/budget-items", h.ListBatchItems)
		r.Get("/api/v1/batches/{batch_id}/budget-items/{id}", h.GetBatchItem)
		r.With(manageBatch).Post("/api/v1/batches/{batch_id}/budget-items", h.CreateBatchItem)
		r.With(manageBatch).Put("/api/v1/batches/{batch_id}/budget-items/{id}", h.UpdateBatchItem)
		r.With(manageBatch).Delete("/api/v1/batches/{batch_id}/budget-items/{id}", h.DeleteBatchItem)

		// Realizations — read: any auth; write: vernonedu_admin only
		r.Get("/api/v1/budget-items/{item_id}/realizations", h.ListRealizations)
		r.Get("/api/v1/budget-items/{item_id}/realizations/{id}", h.GetRealization)
		r.With(manageRealization).Post("/api/v1/budget-items/{item_id}/realizations", h.CreateRealization)
		r.With(manageRealization).Put("/api/v1/budget-items/{item_id}/realizations/{id}", h.UpdateRealization)
		r.With(manageRealization).Delete("/api/v1/budget-items/{item_id}/realizations/{id}", h.DeleteRealization)

		// Summary
		r.Get("/api/v1/batches/{batch_id}/budget-summary", h.GetBatchSummary)
	})
}
```

- [ ] **Step 3: Build to verify compilation**

```bash
cd backend && go build ./...
```

Expected: no errors.

---

### Task 6: Add GET single item handlers

**Files:**
- Modify: `backend/domains/budget/handler.go`

- [ ] **Step 1: Add `GetTemplateItem` handler**

Add after `ListTemplateItems` in `handler.go`:

```go
func (h *Handler) GetTemplateItem(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	item, err := h.svc.GetTemplateItem(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, item)
}
```

- [ ] **Step 2: Add `GetBatchItem` handler**

Add after `ListBatchItems`:

```go
func (h *Handler) GetBatchItem(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	item, err := h.svc.GetBatchItem(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, item)
}
```

- [ ] **Step 3: Add `GetRealization` handler**

Add after `ListRealizations`:

```go
func (h *Handler) GetRealization(w http.ResponseWriter, r *http.Request) {
	id, err := parseUUID(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid id"))
		return
	}
	item, err := h.svc.GetRealization(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	writeJSON(w, http.StatusOK, item)
}
```

- [ ] **Step 4: Add `GetTemplateItem`, `GetBatchItem`, `GetRealization` service methods**

The service currently has no `GetTemplateItem`, `GetBatchItem`, `GetRealization` — only the repository does. Add them to `service.go`:

```go
func (s *Service) GetTemplateItem(ctx context.Context, id uuid.UUID) (*CourseBudgetTemplateItem, error) {
	return s.repo.GetTemplateItem(ctx, id)
}

func (s *Service) GetBatchItem(ctx context.Context, id uuid.UUID) (*BatchBudgetItem, error) {
	return s.repo.GetBatchItem(ctx, id)
}

func (s *Service) GetRealization(ctx context.Context, id uuid.UUID) (*BudgetRealization, error) {
	return s.repo.GetRealization(ctx, id)
}
```

- [ ] **Step 5: Build**

```bash
cd backend && go build ./...
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add backend/domains/budget/handler.go \
        backend/domains/budget/module.go \
        backend/domains/budget/service.go
git commit -m "fix(budget): fix role constant; move RBAC to route middleware; add GET-single endpoints"
```

---

### Task 7: Add `WithUserContext` helper to middleware

`mw.WithUserContext` does not exist yet — only `GetUserContext` is exported. Handler tests need it to inject a fake user without going through JWT.

**Files:**
- Modify: `backend/internal/middleware/auth.go`

- [ ] **Step 1: Add `WithUserContext` to `auth.go`**

Add after `GetUserContext`:
```go
// WithUserContext injects a UserContext into ctx — used in tests.
func WithUserContext(ctx context.Context, uc *UserContext) context.Context {
	return context.WithValue(ctx, userContextKey, uc)
}
```

- [ ] **Step 2: Build**

```bash
cd backend && go build ./...
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add backend/internal/middleware/auth.go
git commit -m "feat(middleware): export WithUserContext for test injection"
```

---

### Task 8: Write HTTP handler tests

**Files:**
- Create: `backend/domains/budget/handler_test.go`

- [ ] **Step 1: Create handler test file**

```go
//go:build integration

package budget_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/budget"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// buildTestRouter mounts budget routes with JWT bypassed — uses a fake UserContext injector.
func buildTestRouter(pool interface{ Close() }, svc *budget.Service, role string) http.Handler {
	h := budget.NewHandler(svc, zap.NewNop())
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	manageTemplate    := mw.RequireRole("course_creator", "vernonedu_admin")
	manageBatch       := mw.RequireRole("course_creator", "vernonedu_admin")
	manageRealization := mw.RequireRole("vernonedu_admin")

	r.Get("/api/v1/courses/{course_id}/budget-templates", h.ListTemplateItems)
	r.Get("/api/v1/courses/{course_id}/budget-templates/{id}", h.GetTemplateItem)
	r.With(manageTemplate).Post("/api/v1/courses/{course_id}/budget-templates", h.CreateTemplateItem)

	r.Get("/api/v1/batches/{batch_id}/budget-items", h.ListBatchItems)
	r.Get("/api/v1/batches/{batch_id}/budget-items/{id}", h.GetBatchItem)
	r.With(manageBatch).Post("/api/v1/batches/{batch_id}/budget-items", h.CreateBatchItem)

	r.Get("/api/v1/budget-items/{item_id}/realizations", h.ListRealizations)
	r.Get("/api/v1/budget-items/{item_id}/realizations/{id}", h.GetRealization)
	r.With(manageRealization).Post("/api/v1/budget-items/{item_id}/realizations", h.CreateRealization)

	r.Get("/api/v1/batches/{batch_id}/budget-summary", h.GetBatchSummary)

	return r
}

func TestRoleEnforcement_TemplateCreate_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := budget.NewService(budget.NewRepository(pool), zap.NewNop())
	router := buildTestRouter(pool, svc, "student")

	courseID := uuid.New()
	req := httptest.NewRequest(http.MethodPost,
		"/api/v1/courses/"+courseID.String()+"/budget-templates",
		http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestRoleEnforcement_TemplateCreate_AllowedForCourseCreator(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	courseID, _ := seedCourseAndTemplates(t, pool)

	svc := budget.NewService(budget.NewRepository(pool), zap.NewNop())
	router := buildTestRouter(pool, svc, "course_creator")

	body := `{"label":"New Line","preset_amount":200,"overridable":true}`
	req := httptest.NewRequest(http.MethodPost,
		"/api/v1/courses/"+courseID.String()+"/budget-templates",
		strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

func TestRoleEnforcement_RealizationCreate_ForbiddenForCourseCreator(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := budget.NewService(budget.NewRepository(pool), zap.NewNop())
	router := buildTestRouter(pool, svc, "course_creator")

	itemID := uuid.New()
	req := httptest.NewRequest(http.MethodPost,
		"/api/v1/budget-items/"+itemID.String()+"/realizations",
		http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestGetSingleTemplateItem_ReturnsItem(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	courseID, _ := seedCourseAndTemplates(t, pool)

	repo := budget.NewRepository(pool)
	items, err := repo.ListTemplateItems(context.Background(), courseID)
	require.NoError(t, err)
	require.NotEmpty(t, items)

	svc := budget.NewService(repo, zap.NewNop())
	router := buildTestRouter(pool, svc, "vernonedu_admin")

	req := httptest.NewRequest(http.MethodGet,
		"/api/v1/courses/"+courseID.String()+"/budget-templates/"+items[0].ID.String(),
		nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)

	var result budget.CourseBudgetTemplateItem
	require.NoError(t, json.NewDecoder(w.Body).Decode(&result))
	require.Equal(t, items[0].ID, result.ID)
}
```

- [ ] **Step 2: Run handler tests**

```bash
cd backend && go test -tags=integration -run "TestRoleEnforcement|TestGetSingle" ./domains/budget/ -v
```

Expected: all PASS.

- [ ] **Step 3: Run full integration test suite for budget**

```bash
cd backend && go test -tags=integration -count=1 -race -p=1 ./domains/budget/ -v
```

Expected: all PASS.

- [ ] **Step 4: Run all integration tests — no regressions**

```bash
cd backend && go test -tags=integration -count=1 -race -p=1 ./... 2>&1 | tail -30
```

Expected: all PASS.

- [ ] **Step 5: Final commit**

```bash
git add backend/domains/budget/handler_test.go
git commit -m "test(budget): add integration and HTTP-layer tests for role enforcement and GET-single endpoints"
```

---

## Self-Review

### Spec Coverage

| Spec requirement | Task |
|---|---|
| Fix `roleAdmin = "admin"` → `"vernonedu_admin"` | Task 5 |
| Move inline role checks to route middleware | Task 5 |
| Template CRUD → `course_creator` or `vernonedu_admin` | Task 5 |
| Batch item CRUD → `course_creator` or `vernonedu_admin` | Task 5 |
| Realization mutations → `vernonedu_admin` only | Task 5 |
| Fix zero UUID `CreatedBy` in `OnBatchCreated` | Task 4 |
| Add `ActorID` to `BatchCreatedPayload` | Task 4 |
| GET single template item endpoint | Tasks 5, 6 |
| GET single batch item endpoint | Tasks 5, 6 |
| GET single realization endpoint | Tasks 5, 6 |
| `ON DELETE SET NULL` on `template_ref_id` | Task 2 |
| `updated_at` on `BudgetRealization` | Tasks 2, 3 |

All requirements covered. `WithUserContext` middleware helper added as prerequisite for handler tests (Task 7).

### Type Consistency

- `OnBatchCreated(ctx, batchID, courseID, actorID uuid.UUID)` — consistent across Task 4 steps (events.go handler and service.go signature both updated).
- `BudgetRealization.UpdatedAt` added to model, scan in `GetRealization` and `ListRealizations` both updated, CREATE uses `now()`.
- `GetTemplateItem`, `GetBatchItem`, `GetRealization` — added to service.go (Task 6 Step 4) and handler.go (Task 6 Steps 1-3) and routes in module.go (Task 5 Step 2). Consistent naming throughout.
