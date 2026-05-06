# Spec: Lead Source Pages — Settings

**Date:** 2026-05-06
**Status:** Approved

---

## Overview

Refactor dan tambah halaman Lead Source di Settings menggunakan tiga template standar: `ListPageTemplate`, `DetailPageTemplate`, `FormPageTemplate`. Saat ini List dan Form sudah ada tapi belum konsisten; Detail page belum ada.

---

## Data Layer

**Service:** `web-dashboard/src/services/lead-source.service.ts` — tidak berubah.

```ts
interface LeadSource {
  id: string
  name: string
  is_active: boolean
}
```

**API endpoints yang tersedia:**
- `GET /settings/lead-sources` — list semua
- `POST /settings/lead-sources` — create
- `PUT /settings/lead-sources/{id}` — update
- `DELETE /settings/lead-sources/{id}` — delete

**Tidak ada** `GET /settings/lead-sources/{id}`. Detail page fetch via `list()` + find by `id` — aman karena dataset kecil.

---

## Routes

| Path | Component | Status |
|------|-----------|--------|
| `/settings/lead-sources` | `LeadSourceListPage` | Refactor |
| `/settings/lead-sources/new` | `LeadSourceFormPage` | Refactor |
| `/settings/lead-sources/:sourceId` | `LeadSourceDetailPage` | **Baru** |
| `/settings/lead-sources/:sourceId/edit` | `LeadSourceFormPage` | Refactor |

---

## 1. LeadSourceListPage

**File:** `web-dashboard/src/pages/Settings/LeadSourceListPage.tsx`

**Template:** `ListPageTemplate<LeadSource>`

**Kolom:**

| Key | Header | Lebar | Keterangan |
|-----|--------|-------|------------|
| `name` | Nama Sumber | — | Icon `Tag` + bold text |
| `is_active` | Status | 120px | Badge "Aktif" / "Nonaktif" |

**Behavior:**
- `onRowClick` → navigate ke `/settings/lead-sources/:id`
- Row action **Edit** → `/settings/lead-sources/:id/edit`
- `deleteConfig` inline: hapus via `leadSourceService.delete(id)`
- `hidePagination: true`
- Add button → `/settings/lead-sources/new`

---

## 2. LeadSourceDetailPage

**File:** `web-dashboard/src/pages/Settings/LeadSourceDetailPage.tsx` (baru)

**Template:** `DetailPageTemplate`

**Header:**
- Icon: `Tag` (lucide)
- Title: `source.name`
- Badge: "Aktif" (success) / "Nonaktif" (neutral)

**Actions:**
- **Edit** → navigate `/settings/lead-sources/:id/edit`
- **Hapus** → `ConfirmDialog` → `leadSourceService.delete(id)` → navigate list

**Tab:**
- Single tab "Informasi": tampilkan Nama + Status sebagai read-only fields

**Data loading:**
- `useQuery` key `['lead-source', sourceId]`
- Fetcher: `leadSourceService.list()` → find by `sourceId`
- Loading: skeleton / spinner
- Not found: navigate back ke list

**Back:** → `/settings/lead-sources`

---

## 3. LeadSourceFormPage

**File:** `web-dashboard/src/pages/Settings/LeadSourceFormPage.tsx`

**Template:** `FormPageTemplate`

**Fields:**

| Field | Type | Validasi | Keterangan |
|-------|------|----------|------------|
| Nama Sumber | `text` input | Required | Placeholder: "cth. Referral, Website" |
| Status | checkbox | — | Hanya tampil saat **edit** |

**Behavior:**
- Mode ditentukan dari `useParams()`: ada `sourceId` → edit, tidak ada → create
- Edit: fetch via `leadSourceService.list()` + find by ID, pre-fill fields
- Submit create → `leadSourceService.create()` → navigate `/settings/lead-sources`
- Submit edit → `leadSourceService.update()` → navigate `/settings/lead-sources/:id`

**Back:** → `/settings/lead-sources` (list)

---

## routes.tsx Changes

Tambah satu lazy import dan satu route:

```tsx
const LeadSourceDetailPage = lazy(() => import('@/pages/Settings/LeadSourceDetailPage'))

// tambah di settings routes:
{ path: 'settings/lead-sources/:sourceId', element: <S><LeadSourceDetailPage /></S> }
```

---

## File Summary

| File | Action |
|------|--------|
| `src/pages/Settings/LeadSourceListPage.tsx` | Refactor |
| `src/pages/Settings/LeadSourceDetailPage.tsx` | Baru |
| `src/pages/Settings/LeadSourceFormPage.tsx` | Refactor |
| `src/app/routes.tsx` | Tambah 1 route + 1 import |
| `src/services/lead-source.service.ts` | Tidak berubah |
