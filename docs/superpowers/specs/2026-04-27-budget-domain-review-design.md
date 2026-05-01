# Budget Domain — Review & Fix Design

**Date:** 2026-04-27  
**Status:** Approved  
**Scope:** Fix bugs, auth gaps, missing endpoints, and DB schema issues in the existing budget domain.

---

## Context

Budget domain tracks operational spend per course batch:

- `CourseBudgetTemplateItem` — preset budget lines at course level (copied to each new batch)
- `BatchBudgetItem` — actual budget lines per batch (inherited from template or added manually)
- `BudgetRealization` — actual spend recorded against a batch item
- `BatchBudgetSummary` — planned vs actual aggregation per batch

Domain wires into the event bus: on `batch.created`, all template items for the course are auto-copied into batch items.

Variance is defined as `planned - actual` (positive = under budget, negative = over budget).

---

## Issues Found

### Bug 1 — Wrong role constant

`handler.go:15` defines `roleAdmin = "admin"`. The correct role name in this system is `"vernonedu_admin"` (matches `team_member/service.go`). All realization mutation guards use the wrong role, so non-admin users with role `"admin"` (which doesn't exist) get blocked while actual admins (`"vernonedu_admin"`) are also blocked.

### Bug 2 — Zero UUID for `CreatedBy` in `OnBatchCreated`

`service.go:127-151` — when `OnBatchCreated` auto-copies template items to batch items, it constructs `BatchBudgetItem` without setting `CreatedBy`. The field defaults to zero UUID (`00000000-...`), which is inserted into DB. The event payload (`batchCreatedPayload`) currently only carries `batch_id` and `course_id`.

### Auth Gap — Template & batch CRUD have no role enforcement

`POST/PUT/DELETE` on template items and batch items are protected by JWT only. Any authenticated user can create/modify/delete budget lines.

**Decided:** Template CRUD and batch item CRUD → `course_creator` or `vernonedu_admin` only.

### Auth Gap — Inline role checks should move to route middleware

Realization mutations do `uc.Role != roleAdmin` inline in handlers. Pattern in this codebase uses `mw.RequireRole(...)` at route level (see `team_member/module.go`). Inline checks should be removed and replaced with route middleware.

### Missing GET single item endpoints

Repository interface defines `GetTemplateItem`, `GetBatchItem`, `GetRealization` but no HTTP handlers or routes expose these. Clients have no way to fetch a single item by ID.

### DB — Missing `ON DELETE SET NULL` on `template_ref_id`

`budget.batch_items.template_ref_id` references `budget.template_items(id)` with no `ON DELETE` behavior. Deleting a template item leaves dangling references in batch items.

### DB — `BudgetRealization` missing `updated_at`

`budget.realizations` has no `updated_at` column but the domain supports `UpdateRealization`. No audit trail for when a realization was last modified.

---

## Design Decisions

### Role names

| Constant | Value |
|---|---|
| `roleVernonAdmin` | `"vernonedu_admin"` |
| `roleCourseCreator` | `"course_creator"` |

### Authorization matrix

| Route group | Allowed roles |
|---|---|
| GET template items (list + single) | JWT (any) |
| POST/PUT/DELETE template items | `course_creator`, `vernonedu_admin` |
| GET batch items (list + single) | JWT (any) |
| POST/PUT/DELETE batch items | `course_creator`, `vernonedu_admin` |
| GET realizations (list + single) | JWT (any) |
| POST/PUT/DELETE realizations | `vernonedu_admin` |
| GET batch summary | JWT (any) |

Enforce via `mw.RequireRole(...)` at route level in `module.go`. Remove all inline role checks from handler methods.

### Fix `OnBatchCreated` — add `actor_id` to event payload

`batchCreatedPayload` gains `ActorID uuid.UUID`. Whoever publishes `batch.created` must include the triggering user's ID. `OnBatchCreated` passes `actorID` into each `BatchBudgetItem.CreatedBy`.

### New GET single endpoints

Add to handler and routes:
- `GET /api/v1/courses/{course_id}/budget-templates/{id}` → `GetTemplateItem`
- `GET /api/v1/batches/{batch_id}/budget-items/{id}` → `GetBatchItem`
- `GET /api/v1/budget-items/{item_id}/realizations/{id}` → `GetRealization`

### DB migrations (new file: `000016_budget_fixes`)

```sql
-- Fix 1: ON DELETE SET NULL for template_ref_id
ALTER TABLE budget.batch_items
  DROP CONSTRAINT budget_batch_items_template_ref_id_fkey,
  ADD CONSTRAINT budget_batch_items_template_ref_id_fkey
    FOREIGN KEY (template_ref_id) REFERENCES budget.template_items(id) ON DELETE SET NULL;

-- Fix 2: Add updated_at to realizations
ALTER TABLE budget.realizations ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
SELECT attach_updated_at_trigger('budget', 'realizations');
```

---

## Files to Change

| File | Change |
|---|---|
| `backend/domains/budget/handler.go` | Remove `roleAdmin` const + inline role checks; add `GetTemplateItem`, `GetBatchItem`, `GetRealization` handlers |
| `backend/domains/budget/module.go` | Add `roleVernonAdmin`, `roleCourseCreator` consts; restructure routes with `mw.RequireRole`; add GET single routes |
| `backend/domains/budget/events.go` | Add `ActorID` to `batchCreatedPayload`; pass to `OnBatchCreated` |
| `backend/domains/budget/service.go` | `OnBatchCreated` signature adds `actorID uuid.UUID`; set `CreatedBy` on copied items |
| `backend/domains/budget/model.go` | Add `UpdatedAt` to `BudgetRealization` |
| `backend/migrations/000016_budget_fixes.up.sql` | `ON DELETE SET NULL` + `updated_at` on realizations |
| `backend/migrations/000016_budget_fixes.down.sql` | Reverse both changes |

---

## Out of Scope

- Budget approval workflow (not requested)
- Budget cap enforcement / alerts (not requested)
- `category` enum constraint (not requested)
- `spent_at DATE` → `TIMESTAMPTZ` migration (low priority, no business impact reported)
