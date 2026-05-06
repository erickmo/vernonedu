# Design: Location List Page Fix

**Date:** 2026-05-05
**Status:** Approved

---

## Problem Statement

`LocationListPage` has 4 issues:
1. Kolom "Jumlah Ruangan" dan "Total Kapasitas" selalu kosong (`—`)
2. Kolom "Fasilitas" tidak diperlukan
3. Search & filter tidak berfungsi (fetcher ignore `params`)
4. Tidak ada nested list untuk ruangan per gedung

---

## Root Causes

| Issue | Root Cause |
|---|---|
| Kolom kosong | `GET /buildings` response tidak include `room_count`/`rooms` — `BuildingListItem` hanya punya `id, name, address, description, created_at, updated_at` |
| Search tidak jalan | Fetcher di `LocationListPage` ignore `params` arg dari `useDataSource` — selalu call `listBuildings()` tanpa search param |
| Filter tidak jalan | Same as above — `params.filters` tidak dikirim ke API |

---

## Scope

**Files yang perlu diubah (semua LOCKED — butuh `YES UNLOCK`):**

### API
- `api/internal/query/list_buildings/handler.go`
- `api/internal/query/list_buildings/query.go`
- `api/infrastructure/database/building_repository.go`

### Frontend
- `web-dashboard/src/pages/Operations/LocationListPage.tsx`
- `web-dashboard/src/services/location.service.ts`

---

## Design

### 1. API — ListBuildings Response Shape

Tambah tipe baru di `list_buildings/handler.go`:

```go
type RoomSummary struct {
  ID       uuid.UUID `json:"id"`
  Name     string    `json:"name"`
  Capacity int       `json:"capacity"`
}

type BuildingListItem struct {
  ID            uuid.UUID      `json:"id"`
  Name          string         `json:"name"`
  Address       string         `json:"address"`
  Description   string         `json:"description"`
  RoomCount     int            `json:"room_count"`
  TotalCapacity int            `json:"total_capacity"`
  Rooms         []RoomSummary  `json:"rooms"`
  CreatedAt     int64          `json:"created_at"`
  UpdatedAt     int64          `json:"updated_at"`
}
```

### 2. API — Search Support

Tambah `Search string` ke `ListBuildingsQuery`:

```go
type ListBuildingsQuery struct {
  Offset int
  Limit  int
  Search string
}
```

Handler parse `?search=` dari URL query string, pass ke query.

### 3. API — Repository Query

`building_repository.go` — method `List` diubah:
- Accept `search string` param
- `WHERE` clause: `b.name ILIKE '%' || $search || '%' OR b.address ILIKE '%' || $search || '%'` (skip if search empty)
- JOIN `rooms` table → `LEFT JOIN rooms r ON r.building_id = b.id`
- GROUP BY `b.id`
- Aggregate: `COUNT(r.id) AS room_count`, `COALESCE(SUM(r.capacity), 0) AS total_capacity`
- `json_agg` untuk rooms array (filter NULL via `WHERE r.id IS NOT NULL`)

Repository interface di `domain/building/` juga perlu update signature (jika interface dideklarasi di sana).

### 4. Frontend — location.service.ts

```ts
listBuildings: (params?: { search?: string; offset?: number; limit?: number }) => {
  const qs = new URLSearchParams()
  if (params?.search) qs.set('search', params.search)
  if (params?.offset) qs.set('offset', String(params.offset))
  if (params?.limit) qs.set('limit', String(params.limit))
  const query = qs.toString() ? `?${qs}` : ''
  return apiClient.get<any>(`/buildings${query}`).then(r => (r as any).data ?? r)
}
```

### 5. Frontend — LocationListPage.tsx

#### Perubahan columns:
- Hapus kolom `facilities`
- Kolom `room_count`: render dari `row.room_count` (number dari API)
- Kolom `total_capacity`: render `${row.total_capacity} orang` dari API

#### Fetcher pakai params:
```ts
fetcher={async (params) => {
  const data = await locationService.listBuildings({
    search: params.search,
    offset: params.offset,
    limit: params.limit,
  })
  const items = Array.isArray(data) ? data : (data as any)?.items ?? (data as any)?.data ?? []
  const total = (data as any)?.total ?? items.length
  return { items, total, limit: params.limit ?? 9999, offset: params.offset ?? 0 }
}}
```

#### Nested list widget (accordion row):
- State: `expandedId: string | null`
- Row klik toggle expand (tidak navigate ke detail)
- Atau: chevron di kolom tersendiri untuk toggle, nama gedung tetap navigasi ke detail
- Expanded row render di bawah row gedung:
  ```tsx
  <div style={{ padding: '8px 16px 8px 56px', background: 'var(--color-surface-alt)' }}>
    <ul style={{ margin: 0, padding: 0, listStyle: 'none', display: 'flex', flexDirection: 'column', gap: 4 }}>
      {row.rooms.map(room => (
        <li key={room.id} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <DoorOpen size={14} />
          <span>{room.name}</span>
          <span style={{ marginLeft: 'auto', fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)' }}>
            {room.capacity} orang
          </span>
        </li>
      ))}
    </ul>
  </div>
  ```
- Jika `row.rooms.length === 0`: tampilkan "Belum ada ruangan"
- Kolom `room_count` di-render sebagai badge yang bisa diklik untuk toggle expand

#### Catatan UX:
- `onRowClick` tetap navigate ke detail page (current behavior)
- Toggle expand via chevron icon di kolom paling kiri ATAU klik badge room count
- Jangan conflict dengan `onRowClick`

---

## Constraints

- Semua files locked → perlu `YES UNLOCK` dulu
- `ListPageTemplate` tidak punya built-in expandable rows → implementasi custom di `LocationListPage` sendiri
- Karena `ListPageTemplate` render `DataTable` internal, expandable row perlu dicek apakah `DataTable` support custom row render atau perlu workaround

---

## Out of Scope

- Filter panel (filterDefs) — tidak ditambah, search saja sudah cukup
- Pagination — tetap `hidePagination` (semua data sekaligus)
- Edit/delete rooms dari list page — tetap di detail page

---

## Implementation Order

1. API: update `list_buildings/query.go` → tambah Search field
2. API: update `building_repository.go` → JOIN rooms, search WHERE clause
3. API: update `list_buildings/handler.go` → parse search param, map rooms ke response
4. Frontend: update `location.service.ts` → pass search param
5. Frontend: update `LocationListPage.tsx` → fix fetcher, update columns, add accordion
