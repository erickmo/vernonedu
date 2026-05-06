# Spec: Franchisee Feature

**Date:** 2026-05-06
**Scope:** Full-stack — Go API + React Dashboard
**Implementation:** Parallel subagents (API + Frontend)

---

## Overview

Add Franchisee management to the Pengembangan section of the dashboard. Covers the full Franchise domain: Franchisee CRUD, Franchise Agreement, Royalty Payment Records, and Branch Other Revenue.

Access: `director` role only.

---

## API Endpoints

```
GET    /api/v1/franchisees                              ?offset, limit, status, search
GET    /api/v1/franchisees/{id}
POST   /api/v1/franchisees
PUT    /api/v1/franchisees/{id}
# No DELETE — franchisees are deactivated via PUT status=inactive/terminated

GET    /api/v1/franchisees/{id}/agreement
POST   /api/v1/franchisees/{id}/agreement
PUT    /api/v1/franchisees/{id}/agreement/{agrId}

GET    /api/v1/franchisees/{id}/royalty-payments        ?period (YYYY-MM)
POST   /api/v1/franchisees/{id}/royalty-payments
PUT    /api/v1/franchisees/{id}/royalty-payments/{rpId}/mark-paid

GET    /api/v1/franchisees/{id}/other-revenue           ?period
POST   /api/v1/franchisees/{id}/other-revenue
PUT    /api/v1/franchisees/{id}/other-revenue/{revId}
DELETE /api/v1/franchisees/{id}/other-revenue/{revId}
```

Response shapes follow backend standard:
- Single item: `{ "data": { ... } }`
- Paginated list: `{ "data": { "data": [...], "total": N, "offset": 0, "limit": 20 } }`

---

## Domain Entities

### Franchisee
| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | string | Owner/investor name |
| branch_name | string | Branch name |
| location | string | City/address |
| contact | string | |
| status | enum | active, inactive, terminated |
| created_by | User | |
| created_at | datetime | |

### FranchiseAgreement
| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| franchisee_id | uuid | FK |
| buy_in_fee | decimal | One-time signing fee |
| monthly_royalty | decimal | Fixed monthly amount |
| revenue_royalty_pct | decimal | 0–100, % of gross branch revenue |
| start_date | date | |
| end_date | date | Nullable |
| status | enum | active, inactive, terminated |

### RoyaltyPaymentRecord
| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| franchise_agreement_id | uuid | FK |
| period | string | YYYY-MM |
| gross_revenue | decimal | |
| monthly_royalty | decimal | From agreement |
| revenue_royalty | decimal | gross_revenue × revenue_royalty_pct |
| total_royalty | decimal | monthly + revenue |
| status | enum | unpaid, overdue, paid |
| paid_at | datetime | Nullable |
| recorded_by | User | |
| created_at | datetime | |

### BranchOtherRevenue
| Field | Type | Notes |
|---|---|---|
| id | uuid | PK |
| franchisee_id | uuid | FK |
| label | string | e.g. "Event fee", "Space rental" |
| amount | decimal | |
| revenue_date | date | |
| added_by | User | |
| created_at | datetime | |

---

## Go API Architecture

Clean Architecture + CQRS. Structure:

```
api/internal/
├── domain/franchise/
│   ├── franchisee.go           ← entities + repo interfaces
│   └── franchise_agreement.go
├── command/
│   ├── create_franchisee/
│   ├── update_franchisee/
│   ├── create_agreement/
│   ├── update_agreement/
│   ├── create_royalty_payment/
│   ├── mark_royalty_paid/
│   ├── create_other_revenue/
│   ├── update_other_revenue/
│   └── delete_other_revenue/
├── query/
│   ├── list_franchisees/
│   ├── get_franchisee/
│   ├── get_agreement/
│   ├── list_royalty_payments/
│   └── list_other_revenue/
├── delivery/http/
│   └── franchise_handler.go
└── infrastructure/database/
    ├── franchise_repo.go
    └── migrations/XXXX_create_franchise_tables.sql
```

- DI via Uber FX
- Role guard `director` on all routes via existing middleware
- 4 migration tables: `franchisees`, `franchise_agreements`, `royalty_payment_records`, `branch_other_revenues`

---

## Frontend Architecture

### Routes (add to `routes.tsx`)

```
/pengembangan/franchisees          → FranchiseeListPage
/pengembangan/franchisees/new      → FranchiseeFormPage
/pengembangan/franchisees/:id      → FranchiseeDetailPage
/pengembangan/franchisees/:id/edit → FranchiseeFormPage (edit mode)
```

### Nav Item

Add to Pengembangan section in `navItems.ts` after Lokasi:

```ts
{
  key: 'franchisees',
  label: 'Franchisee',
  path: '/pengembangan/franchisees',
  icon: Store,
  hasAccess: (ctx) => hasRole(ctx, 'director'),
}
```

### FranchiseeListPage

Uses `ListPageTemplate`. Columns:

| Column | Key | Notes |
|---|---|---|
| Nama Franchisee | name | Bold, with Store icon |
| Nama Branch | branch_name | |
| Lokasi | location | |
| Status | status | Badge: active=green, inactive=yellow, terminated=red |

- Search by name/branch
- Filter by status dropdown
- Row click → DetailPage

### FranchiseeFormPage

Uses `FormPageTemplate`. Fields:

| Field | Type | Required |
|---|---|---|
| Nama | text | yes |
| Nama Branch | text | yes |
| Lokasi | text | yes |
| Kontak | text | no |
| Status | select (active/inactive/terminated) | yes |

- New mode: on save → navigate to list
- Edit mode: on save → navigate back to detail

### FranchiseeDetailPage

Uses `DetailPageTemplate` with sidebar section navigation.

Header actions: **Edit** (→ form). No delete — deactivate via status field in form.

Sidebar sections:

| Section Key | Label | Content |
|---|---|---|
| info | Info | InfoRow grid: name, branch_name, location, contact, status, created_at |
| agreement | Perjanjian | buy_in_fee, monthly_royalty, revenue_royalty_pct, start_date, end_date, status |
| royalty | Royalty Payments | Table: period, gross_revenue, monthly_royalty, revenue_royalty, total_royalty, status badge, paid_at |
| other-revenue | Pendapatan Lain | Table: label, amount, revenue_date |

### Service File

`web-dashboard/src/services/franchisee.service.ts` — uses `apiClient` directly (not `createEntityService`) due to nested sub-resource endpoints.

---

## Business Rules (enforced API-side)

1. `revenue_royalty_pct` must be 0–100
2. One agreement per franchisee at a time (status: active)
3. RoyaltyPaymentRecord: `revenue_royalty = gross_revenue × revenue_royalty_pct / 100`
4. RoyaltyPaymentRecord: `total_royalty = monthly_royalty + revenue_royalty`
5. Mark-paid only allowed when status is `unpaid` or `overdue`
6. No hard delete on franchisees — deactivate via status (inactive/terminated) only

---

## Implementation Strategy

Parallel subagents:
- **Subagent A (API):** Go backend — domain, commands, queries, handler, migration, FX wiring
- **Subagent B (Frontend):** React — service, list/detail/form pages, nav item, routes

Both work from this spec as the shared contract. No sequential dependency.
