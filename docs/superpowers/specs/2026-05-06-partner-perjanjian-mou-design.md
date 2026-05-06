# Partner Perjanjian (MOU) — Design Spec

**Date:** 2026-05-06  
**Branch:** feat/partner-perjanjian-mou  
**Scope:** MOU CRUD in PartnerDetailPage + PartnerMOUListPage + Dashboard widget

---

## Background

Backend MOU API is fully implemented. Frontend `PartnerDetailPage` has a placeholder MOU tab
("fitur segera hadir"). `partner.service.ts` has `addMOU` but is missing `listMOUs`,
`updateMOU`, `deleteMOU`, `listExpiringMOUs`. No global `GET /mous` endpoint exists — only
per-partner list and a `/mous/expiring` endpoint.

---

## API Endpoints (no backend changes required)

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/partners/:id/mou` | Create MOU |
| `GET` | `/partners/:id/mous` | List MOUs per partner |
| `PUT` | `/mous/:id` | Update MOU |
| `DELETE` | `/mous/:id` | Delete MOU |
| `GET` | `/mous/expiring?within_months=N` | List expiring MOUs (cross-partner) |

---

## MOU Data Shape

```ts
interface MOU {
  id: string
  partner_id: string
  document_number: string
  title: string
  start_date: string     // ISO date
  end_date?: string      // ISO date, optional
  status: 'active' | 'expiring' | 'expired' | 'terminated'
  document_url?: string
  notes?: string
  created_at: string
  updated_at: string
}

interface ExpiringMOU extends MOU {
  partner_name: string   // included in expiring endpoint response
}
```

---

## Part 1 — `PartnerDetailPage`: MOU Tab Implementation

**File:** `web-dashboard/src/pages/BusinessDev/PartnerDetailPage.tsx`

Replace placeholder content in the existing MOU tab section.

### 1.1 MOU Form Modal (`MOUFormModal`)

Inline component, co-located in `PartnerDetailPage.tsx`.

**Trigger:**
- "Tambah MOU" button in MOU tab header → create mode
- Edit icon per row → edit mode (pre-fills form with row data)

**Fields:**

| Field | Input Type | Validation |
|---|---|---|
| `title` | text | required |
| `document_number` | text | required |
| `start_date` | date | required |
| `end_date` | date | optional |
| `status` | select: `active` / `expiring` / `expired` / `terminated` | required |
| `document_url` | text (URL) | optional |
| `notes` | textarea | optional |

**Submit logic:**
- Create mode: `partnerService.addMOU(partnerId, payload)` → `POST /partners/:id/mou`
- Edit mode: `partnerService.updateMOU(mouId, payload)` → `PUT /mous/:id`
- On success: `queryClient.invalidateQueries(['partner-mous', partnerId])` + `toast.success`
- On error: `toast.error`

### 1.2 MOU List Table

Columns: No. Dokumen | Judul | Mulai | Berakhir | Status | Aksi

Status badge colors:
- `active` → green
- `expiring` → yellow/amber
- `expired` → red
- `terminated` → gray

**Per-row actions:**
- Edit icon → open `MOUFormModal` in edit mode
- Trash icon → `window.confirm()` → `partnerService.deleteMOU(mouId)` → invalidate

### 1.3 State

```ts
const [mouModalOpen, setMouModalOpen] = useState(false)
const [editingMOU, setEditingMOU] = useState<MOU | null>(null)
// null = create mode, non-null = edit mode
```

Query key: `['partner-mous', partnerId]`

---

## Part 2 — `PartnerMOUListPage` (new file)

**File:** `web-dashboard/src/pages/Partners/PartnerMOUListPage.tsx`

Focus: MOU monitoring dashboard — not a flat list of all MOUs.

### 2.1 Section A — MOU Segera Berakhir

- Fetch: `partnerService.listExpiringMOUs(3)` → `GET /mous/expiring?within_months=3`
- Table: Partner | Judul | No. Dokumen | Berakhir | Sisa Hari | Status badge
- "Sisa Hari" = `Math.ceil((new Date(end_date) - Date.now()) / 86400000)` displayed as chip: `N hari lagi`
- Empty state: "Tidak ada MOU yang akan berakhir dalam 3 bulan"
- Link per row → `navigate('/partners/:partnerId')` detail page

### 2.2 Section B — Semua Partner & Status MOU

- Fetch: `partnerService.list({ limit: 200 })` — `mou_status` field already in partner list response
- Table: Nama Partner | Grup | Status MOU badge | Aksi
- Filter bar: status MOU select (All / Active / Expiring / Expired / No MOU)
- Filter runs client-side against fetched list
- "Lihat Detail" button → `navigate('/partners/:partnerId')`

### 2.3 Page Layout

```
<PageHeader title="Perjanjian MOU" />
<SectionCard title="MOU Segera Berakhir (3 bulan ke depan)">
  <table />  ← Section A
</SectionCard>
<SectionCard title="Semua Partner">
  <filter bar />
  <table />  ← Section B
</SectionCard>
```

---

## Part 3 — Dashboard Widget "MOU Berakhir"

**File:** `web-dashboard/src/pages/Dashboard/DashboardPage.tsx`

Add compact widget in DashboardPage.

- Fetch: `partnerService.listExpiringMOUs(3)` → `GET /mous/expiring?within_months=3`
- Display: max 5 rows — Partner Name | Judul | Berakhir (relative: "N hari lagi")
- Footer link: "Lihat semua →" → `/partners/mous`
- Empty state: "Tidak ada MOU yang akan berakhir dalam 3 bulan" (hidden or collapsed)
- Role gate: only render for `director`, `operation_leader`

---

## Part 4 — Service & Types Updates

### `partner.service.ts` — add missing methods

```ts
listMOUs: (partnerId: string) =>
  apiClient.get<unknown>(`partners/${partnerId}/mous`)
    .then((r: any) => { const outer = (r as any).data ?? r; return Array.isArray(outer) ? outer : (outer?.data ?? outer?.items ?? []) }),

updateMOU: (mouId: string, data: Partial<MOUPayload>) =>
  apiClient.put<any>(`mous/${mouId}`, data),

deleteMOU: (mouId: string) =>
  apiClient.delete<any>(`mous/${mouId}`),

listExpiringMOUs: (withinMonths: number = 3) =>
  apiClient.get<unknown>(`mous/expiring?within_months=${withinMonths}`)
    .then((r: any) => { const outer = (r as any).data ?? r; return Array.isArray(outer) ? outer : (outer?.data ?? outer?.items ?? []) }),
```

### `types/partner.types.ts` — add MOU types

```ts
export type MOUStatus = 'active' | 'expiring' | 'expired' | 'terminated'

export interface MOU {
  id: string
  partner_id: string
  document_number: string
  title: string
  start_date: string
  end_date?: string
  status: MOUStatus
  document_url?: string
  notes?: string
  created_at: string
  updated_at: string
}

export interface ExpiringMOU extends MOU {
  partner_name: string
}

export interface MOUPayload {
  document_number: string
  title: string
  start_date: string
  end_date?: string
  status: MOUStatus
  document_url?: string
  notes?: string
}
```

---

## Part 5 — Route & Nav Updates

### `routes.tsx`

```tsx
const PartnerMOUListPage = lazy(() => import('@/pages/Partners/PartnerMOUListPage'))

// add inside partners group:
{ path: 'partners/mous', element: <S><PartnerMOUListPage /></S> },
```

> Route `partners/mous` must appear BEFORE `partners/:partnerId` to avoid `:partnerId` matching "mous".

### `navItems.ts`

Convert Partner nav item to have sub-items:

```ts
{
  key: 'partners',
  label: 'Partner',
  icon: Handshake,
  children: [
    { key: 'partners-list', label: 'Daftar Partner', path: '/partners' },
    { key: 'partners-mous', label: 'Perjanjian MOU',  path: '/partners/mous' },
  ],
  hasAccess: (ctx) => hasAnyRole(ctx, ['director', 'operation_leader', 'education_leader']),
},
```

> Only if sidebar supports `children` sub-items. Check existing sidebar implementation before implementing — if not supported, add as a separate top-level item instead.

---

## Files Summary

| File | Action |
|---|---|
| `web-dashboard/src/pages/BusinessDev/PartnerDetailPage.tsx` | Edit — implement MOU tab |
| `web-dashboard/src/pages/Partners/PartnerMOUListPage.tsx` | **Create** |
| `web-dashboard/src/pages/Dashboard/DashboardPage.tsx` | Edit — add expiring MOU widget |
| `web-dashboard/src/services/partner.service.ts` | Edit — add MOU service methods |
| `web-dashboard/src/types/partner.types.ts` | Edit/Create — add MOU types |
| `web-dashboard/src/app/routes.tsx` | Edit — add `/partners/mous` route |
| `web-dashboard/src/layouts/AppSidebar/navItems.ts` | Edit — add MOU sub-item |

**No backend changes required.**

---

## Out of Scope

- MOU document upload (only URL input — no file upload endpoint exists)
- MOU renewal workflow / notifications
- Bulk MOU operations
- Global `GET /mous` endpoint (not available in backend)

---

**Last Updated:** 2026-05-06
