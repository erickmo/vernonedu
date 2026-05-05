# Universal List Query — Design Spec

**Date:** 2026-05-05  
**Status:** Approved  
**Scope:** All `GET /api/v1/{entity}` list endpoints + frontend ListPageTemplate

---

## Problem

All entity list endpoints only accept `offset` + `limit`. `search`, `sort`, and `filters` sent by the frontend are silently ignored. The frontend `ListPageTemplate` already has working UI for search, sort, and filters — but nothing reaches the backend.

---

## Solution

Build a shared `pkg/queryparam` package (Go) that parses and validates sort + filters from URL query params, then update all 25 list endpoints to use it. Update frontend `useDataSource` to convert the search input into a filter tuple instead of a separate param.

---

## Package: `api/pkg/queryparam`

### Files

```
api/pkg/queryparam/
├── types.go    — QueryParams, SortClause, FilterClause
├── parse.go    — Parse(q url.Values, allowed map[string]string) (*QueryParams, error)
└── build.go    — BuildWhere(), BuildOrder()
```

### Types

```go
type SortClause struct {
    Field string // validated SQL column name (from allowedFields map)
    Dir   string // "ASC" | "DESC"
}

type FilterClause struct {
    Field string
    Op    string
    Value interface{}
}

type QueryParams struct {
    Offset  int
    Limit   int
    Sorts   []SortClause
    Filters []FilterClause
}
```

### Parse

```go
func Parse(q url.Values, allowed map[string]string) (*QueryParams, error)
```

- Reads `offset`, `limit`, `sort`, `filters` from URL query values
- `sort` format: JSON-encoded `[["field", 1], ["field", -1]]` — `1` = ASC, `-1` = DESC
- `filters` format: JSON-encoded `[["field", "op", "value"], ...]`
- `allowed` = `{"frontend_name": "sql_column"}` — whitelist per entity
- Any field NOT in `allowed` → returns `400 Bad Request`
- `limit` default: `10`, max: `200`
- `offset` default: `0`

### BuildWhere

```go
func BuildWhere(filters []FilterClause, startIdx int) (string, []interface{}, int)
```

Returns `(whereClause, args, nextArgIdx)`.

- Empty filters → returns `("", nil, startIdx)`
- Multiple filters joined with `AND`, **except** consecutive `like` operators on different fields → joined with `OR` (enables multi-field search)
- `null` / `not_null` operators → no value arg added

### BuildOrder

```go
func BuildOrder(sorts []SortClause, defaultClause string) string
```

- Empty sorts → returns `defaultClause`
- Multiple sort fields joined with `, `

### Supported Operators

| Operator | SQL Output | Value Type |
|---|---|---|
| `eq` | `col = $n` | scalar |
| `neq` | `col != $n` | scalar |
| `like` | `col ILIKE '%' \|\| $n \|\| '%'` | string |
| `starts_with` | `col ILIKE $n \|\| '%'` | string |
| `ends_with` | `col ILIKE '%' \|\| $n` | string |
| `gt` | `col > $n` | scalar |
| `gte` | `col >= $n` | scalar |
| `lt` | `col < $n` | scalar |
| `lte` | `col <= $n` | scalar |
| `null` | `col IS NULL` | none |
| `not_null` | `col IS NOT NULL` | none |
| `in` | `col = ANY($n)` | JSON array → `pq.Array` |
| `not_in` | `col != ALL($n)` | JSON array → `pq.Array` |
| `between` | `col BETWEEN $n AND $m` | JSON array `["start","end"]` |

Unknown operator → `Parse()` returns error.

---

## Backend: Per-Entity Pattern

### 1. Domain Interface

Every `ReadRepository` in `internal/domain/{entity}/{entity}.go`:

```go
// BEFORE
List(ctx context.Context, offset, limit int) ([]*Entity, int, error)

// AFTER
List(ctx context.Context, params queryparam.QueryParams) ([]*Entity, int, error)
```

### 2. Query Handler

Every `internal/query/list_{entity}/handler.go`:

```go
type ListEntityQuery struct {
    queryparam.QueryParams  // embed
}
```

Handler passes `q.QueryParams` directly to repo. No field unpacking needed.

### 3. Repository

Every `infrastructure/database/{entity}_repository.go`:

```go
func (r *EntityRepository) List(ctx context.Context, params queryparam.QueryParams) ([]*domain.Entity, int, error) {
    where, args, nextIdx := queryparam.BuildWhere(params.Filters, 1)
    order := queryparam.BuildOrder(params.Sorts, "e.created_at DESC")

    countQuery := `SELECT COUNT(*) FROM entities e` + where
    if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil { ... }

    limitArg, offsetArg := nextIdx, nextIdx+1
    args = append(args, params.Limit, params.Offset)
    query := fmt.Sprintf(`SELECT e.* FROM entities e %s %s LIMIT $%d OFFSET $%d`,
        where, order, limitArg, offsetArg)
    // ...
}
```

### 4. HTTP Handler

Every `internal/delivery/http/{entity}_handler.go`:

```go
var departmentAllowedFields = map[string]string{
    "name":        "d.name",
    "is_active":   "d.is_active",
    "created_at":  "d.created_at",
    "leader_name": "u.name",
}

func (h *EntityHandler) List(w http.ResponseWriter, r *http.Request) {
    params, err := queryparam.Parse(r.URL.Query(), entityAllowedFields)
    if err != nil {
        writeError(w, http.StatusBadRequest, err.Error())
        return
    }
    result, err := h.qryBus.Execute(r.Context(), &list_entity.ListEntityQuery{QueryParams: *params})
    if err != nil {
        writeError(w, http.StatusInternalServerError, "failed to list entities")
        return
    }
    writeJSON(w, http.StatusOK, result)
}
```

---

## Entities to Update (25 total)

| # | Entity | Query Handler | HTTP Handler | Repo |
|---|---|---|---|---|
| 1 | Departments | `list_department` | `department_handler.go` | `department_repository.go` |
| 2 | Users | `list_users` | `user_handler.go` | `user_repository.go` |
| 3 | Courses | `list_courses` | `curriculum_handler.go` | `course_repository.go` |
| 4 | Course Types | `list_course_types` | `curriculum_handler.go` | `course_type_repository.go` |
| 5 | Course Versions | `list_course_versions` | `curriculum_handler.go` | `course_version_repository.go` |
| 6 | Course Modules | `list_course_modules` | `curriculum_handler.go` | `course_module_repository.go` |
| 7 | Course Batches | `list_course_batches` | `batch_handler.go` | `batch_repository.go` |
| 8 | Students | `list_students` | `student_handler.go` | `student_repository.go` |
| 9 | Enrollments | `list_enrollments` | `enrollment_handler.go` | `enrollment_repository.go` |
| 10 | Talent Pool | `list_talentpool` | `talentpool_handler.go` | `talentpool_repository.go` |
| 11 | Buildings | `list_buildings` | `location_handler.go` | `building_repository.go` |
| 12 | Rooms | `list_rooms` | `location_handler.go` | `room_repository.go` |
| 13 | Approvals | `list_approvals` | `approval_handler.go` | `approval_repository.go` |
| 14 | Notifications | `list_notifications` | `notification_handler.go` | `notification_repository.go` |
| 15 | Certificates | `list_certificates` | `certificate_handler.go` | `certificate_repository.go` |
| 16 | Finance Invoices | `list_invoices` | `finance_handler.go` | `invoice_repository.go` |
| 17 | Finance Payables | `list_payables` | `finance_handler.go` | `payable_repository.go` |
| 18 | Finance Transactions | `list_transactions` | `finance_handler.go` | `transaction_repository.go` |
| 19 | Leads | `list_leads` | `lead_handler.go` | `lead_repository.go` |
| 20 | Partners | `list_partners` | `partner_handler.go` | `partner_repository.go` |
| 21 | Employees | `list_employees` | `hrm_handler.go` | `employee_repository.go` |
| 22 | Leave Requests | `list_leave_requests` | `hrm_handler.go` | `leave_repository.go` |
| 23 | Payroll Periods | `list_payroll_periods` | `hrm_handler.go` | `payroll_repository.go` |
| 24 | Delegations | `list_delegations` | `delegation_handler.go` | `delegation_repository.go` |
| 25 | Marketing Posts | `list_marketing_posts` | `marketing_handler.go` | `marketing_repository.go` |

---

## Frontend Changes

### `hooks/useDataSource.ts`

Add `searchFields?: string[]` config (default: `['name']`).

Convert search state to filter tuples before building `ListParams`:

```ts
filters: [
  ...activeFilters,
  ...(search && searchFields.length
    ? searchFields.map(f => [f, 'like', search] as FilterTuple)
    : []),
]
```

Remove `search` key from `ListParams` sent to fetcher.

### `widgets/ListPageTemplate/ListPageTemplate.tsx`

Add `searchFields?: string[]` prop, forwarded to `useDataSource`.

### `services/department.service.ts`

Fix `buildQS` to use `JSON.stringify` for arrays:

```ts
q.set(k, Array.isArray(v) ? JSON.stringify(v) : String(v))
```

### `pages/Departments/DepartmentListPage.tsx`

Add `filterDefs` + `searchFields`:

```tsx
searchFields={['name', 'description']}
filterDefs={[
  { key: 'is_active', label: 'Status', type: 'select',
    options: [{ value: 'true', label: 'Aktif' }, { value: 'false', label: 'Nonaktif' }] }
]}
```

### Other list pages

Add `filterDefs` + `searchFields` per entity as needed (separate task per entity).

---

## Response Format

No change to existing response shape:

```json
{
  "data": [...],
  "total": 42,
  "offset": 0,
  "limit": 10
}
```

---

## Error Handling

| Scenario | HTTP Status | Message |
|---|---|---|
| Unknown field in sort/filter | 400 | `"invalid field: {field}"` |
| Unknown operator | 400 | `"invalid operator: {op}"` |
| Malformed JSON in sort/filters | 400 | `"invalid sort format"` / `"invalid filters format"` |
| `between` value not 2-element array | 400 | `"between operator requires [start, end] value"` |
| `in`/`not_in` value not array | 400 | `"in operator requires array value"` |

---

## Security

- **SQL injection**: Impossible — all field names validated against whitelist before use in SQL. Only positional args (`$n`) used for values.
- **Field whitelist** defined per handler (not per repo) — handler owns the allowed surface.
- **Max limit**: 200 rows per request enforced in `Parse()`.

---

## Out of Scope

- Full-text search (PostgreSQL `tsvector`) — `like` operator covers current needs
- Nested field filtering (e.g., `batch.course.name`) — flat fields only
- Public endpoints (`/api/v1/public/*`) — no auth, not updated
- Aggregation endpoints (`/summaries`, `/reports/*`) — not list endpoints
