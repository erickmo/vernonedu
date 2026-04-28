# Franchise Portal — Complete Design Spec

**Date:** 2026-04-28
**Status:** Approved
**Scope:** Wire Dashboard from mock → real API + add 4 new pages (Royalty, Team Members, Enrollments, Payments) to make franchise portal fully functional.

---

## Problem

Franchise portal currently has 2 pages (Dashboard + Courses). Dashboard uses hardcoded mock data. There is no way for a franchisee user to view royalty records, enrollments, payments, or team members. Additionally, no backend mechanism links a logged-in user to their franchisee record.

---

## Backend Prerequisite

### 1. Migration — add `user_id` to franchisees

`franchise.franchisees` has no `user_id` column. A franchisee user cannot discover their own franchisee record without this link.

**New migration file:** `backend/migrations/000018_franchise_user_link.up.sql`

```sql
ALTER TABLE franchise.franchisees
  ADD COLUMN user_id UUID REFERENCES identity.users(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX idx_franchisees_user_id ON franchise.franchisees(user_id)
  WHERE user_id IS NOT NULL;
```

**Down:** `backend/migrations/000018_franchise_user_link.down.sql`

```sql
DROP INDEX IF EXISTS franchise.idx_franchisees_user_id;
ALTER TABLE franchise.franchisees DROP COLUMN IF EXISTS user_id;
```

### 2. New endpoint — `GET /api/v1/me/franchisee`

Returns the franchisee record for the currently logged-in user (role: `franchisee`).

- Auth: JWT required, `role = franchisee`
- Lookup: `SELECT * FROM franchise.franchisees WHERE user_id = $1` (from JWT `sub`)
- Response: `Franchisee` JSON (same shape as existing `GetFranchisee` response)
- 404 if no franchisee linked to user

**File changes:**
- `backend/domains/franchise/repository.go` — add `GetFranchiseeByUserID(ctx, userID uuid.UUID) (*Franchisee, error)`
- `backend/domains/franchise/service.go` — add `GetMyFranchisee(ctx, userID uuid.UUID) (*Franchisee, error)`
- `backend/domains/franchise/handler.go` — add `GetMyFranchisee` handler
- `backend/domains/franchise/module.go` — register `GET /api/v1/me/franchisee` (auth required, no role restriction beyond JWT)

### 3. Update `Franchisee` model

Add `UserID *uuid.UUID \`json:"user_id,omitempty"\`` to the `Franchisee` struct in `backend/domains/franchise/model.go`.

---

## Frontend Architecture

### Franchisee Context

A `FranchiseeContext` holds the resolved `franchisee_id` for the session. Fetched once on portal mount via `GET /api/v1/me/franchisee`.

```
src/portals/franchise/FranchiseeContext.tsx
```

- Provider wraps `FranchiseLayout`
- `useFranchisee()` hook returns `{ franchisee, isLoading }`
- All franchise-scoped pages consume this hook for their `franchisee_id`

### New API Files

| File | Covers |
|------|--------|
| `src/lib/api/franchise.ts` | `useFranchisee()`, `useRoyaltyRecords()`, `useMarkRoyaltyPaid()`, `useAgreement()` |
| `src/lib/api/team_member.ts` | `useTeamMembers()`, `useFeeTiers()`, `useProposals()` |

Existing `enrollment.ts` and `finance.ts` already have the hooks needed — reuse as-is.

### Routing

Add 4 routes to `FranchisePortal.tsx`:

```
/franchise/royalty       → Royalty.tsx
/franchise/team          → TeamMembers.tsx
/franchise/enrollments   → Enrollments.tsx (franchise view)
/franchise/payments      → Payments.tsx (franchise view)
```

Update `NAV_ITEMS` in `FranchisePortal.tsx`:

```ts
{ to: '/franchise', label: 'Dashboard', end: true },
{ to: '/franchise/royalty', label: 'Royalty' },
{ to: '/franchise/enrollments', label: 'Enrollments' },
{ to: '/franchise/payments', label: 'Payments' },
{ to: '/franchise/team', label: 'Team' },
```

`/franchise/courses` stays unchanged (already wired to catalog API).

---

## Pages

### Dashboard (wire mock → real)

**File:** `src/portals/franchise/pages/Dashboard.tsx`

Replace `MOCK_MONTHLY_DATA`, `CURRENT`, `PREV`, `REVENUE_GROWTH` constants with:
- `useFranchisee()` — branch name, status
- `useRoyaltyRecords(franchiseeId)` — list royalty records, derive monthly revenue + royalty from `enrollment_revenue` + `monthly_royalty_amount`
- `useAgreement(franchiseeId)` — show `revenue_royalty_pct` as royalty rate

Keep existing chart and card layout. Only replace data source.

### Royalty

**File:** `src/portals/franchise/pages/Royalty.tsx`

- List royalty records by period (month/year)
- Columns: Period, Enrollment Revenue, Other Revenue, Royalty Amount, Status (badge: paid/unpaid/overdue), Paid At
- Action: "Mark Paid" button for unpaid/overdue records (admin only — hide for franchisee role)
- Filter: SubNavBar tabs → All / Unpaid / Paid

### Enrollments

**File:** `src/portals/franchise/pages/Enrollments.tsx`

- Reuse `useEnrollments()` from `enrollment.ts`
- Display all enrollments (franchisee sees all, no backend filter yet — frontend display only)
- Columns: Student Name (from enrollment), Batch, Status (badge), Payment Status, Enrolled At
- SubNavBar tabs: All / Pending / Confirmed / Completed

### Payments

**File:** `src/portals/franchise/pages/Payments.tsx`

- Reuse `useInvoices()` from `finance.ts`
- Columns: Invoice #, Student, Amount, Status (badge), Due Date, Paid At
- SubNavBar tabs: All / Pending / Paid / Overdue

### Team Members

**File:** `src/portals/franchise/pages/TeamMembers.tsx`

- `useTeamMembers()` from `team_member.ts`
- Read-only view (franchise cannot manage team — VernonEdu manages internally)
- Columns: Name, Role (facilitator/staff), Status badge, Joined At
- Filter: SubNavBar tabs → All / Facilitators / Staff

---

## Data Flow

```
FranchisePortal
  └─ FranchiseeProvider
       └─ FranchiseLayout
            └─ pages consume useFranchisee() to get franchiseeId
                 ├─ Dashboard: useRoyaltyRecords(franchiseeId)
                 ├─ Royalty: useRoyaltyRecords(franchiseeId)
                 ├─ Enrollments: useEnrollments() [unfiltered for now]
                 ├─ Payments: useInvoices() [unfiltered for now]
                 └─ TeamMembers: useTeamMembers()
```

---

## Error Handling

- `GET /api/v1/me/franchisee` 404 → show "No franchisee account linked" message, prevent portal access
- Loading states: use `LoadingSpinner` (existing shared component)
- API errors: use existing `ErrorBoundary` component

---

## Testing

- Backend: add `handler_test.go` case for `GET /api/v1/me/franchisee` (401 + 200 + 404 no-link)
- Backend: migration rolls up and down cleanly
- Frontend: manual smoke test each page with franchisee JWT

---

## Out of Scope

- Backend filtering of enrollments/payments by franchisee_id (requires linking batches/invoices to franchisee — future work)
- Franchise revenue entry (`POST /api/v1/franchise-revenues`) — admin operation
- Royalty record creation — admin operation
- Facilitator proposal creation — internal team operation
