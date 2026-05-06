# Location List Page Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix LocationListPage — populate room count/capacity columns, remove facilities column, enable server-side search, and add accordion rows showing rooms per building.

**Architecture:** API `ListBuildings` extended with a new `ListWithRooms` repo method that JOINs rooms. Frontend `DataTable` gains `expandedRow` prop; `LocationListPage` uses it to render rooms accordion. Fetcher passes `params.search` to API.

**Tech Stack:** Go + sqlx (API), React 18 + TypeScript (frontend), PostgreSQL `json_agg` for room aggregation.

---

## File Map

| File | Change |
|---|---|
| `api/internal/domain/building/building.go` | Add `RoomSummary`, `BuildingWithRooms` types; add `ListWithRooms` to `ReadRepository` |
| `api/internal/query/list_buildings/query.go` | Add `Search string` field |
| `api/internal/query/list_buildings/handler.go` | Use `ListWithRooms`, map rooms into response |
| `api/internal/delivery/http/location_handler.go` | Parse `?search=` query param |
| `api/infrastructure/database/building_repository.go` | Implement `ListWithRooms` with JOIN + json_agg |
| `web-dashboard/src/widgets/DataTable/DataTable.tsx` | Add `expandedRow` prop + accordion `<tr>` |
| `web-dashboard/src/widgets/ListPageTemplate/ListPageTemplate.tsx` | Thread `expandedRow` prop through to DataTable |
| `web-dashboard/src/services/location.service.ts` | Add `search?` param to `listBuildings` |
| `web-dashboard/src/pages/Operations/LocationListPage.tsx` | Fix fetcher, columns, add accordion |

---

## Task 1: Domain — Add RoomSummary, BuildingWithRooms, ListWithRooms interface

**Files:**
- Modify: `api/internal/domain/building/building.go`
- Test: `api/internal/domain/building/building_test.go`

- [ ] **Step 1: Write test for BuildingWithRooms struct**

Add to `api/internal/domain/building/building_test.go`:

```go
func TestBuildingWithRooms_ZeroRooms(t *testing.T) {
	b := building.BuildingWithRooms{
		Building:      building.Building{Name: "Gedung A"},
		RoomCount:     0,
		TotalCapacity: 0,
		Rooms:         []building.RoomSummary{},
	}
	if b.RoomCount != 0 {
		t.Errorf("expected 0, got %d", b.RoomCount)
	}
	if len(b.Rooms) != 0 {
		t.Errorf("expected empty rooms, got %d", len(b.Rooms))
	}
}

func TestBuildingWithRooms_WithRooms(t *testing.T) {
	id := uuid.New()
	b := building.BuildingWithRooms{
		Building:      building.Building{Name: "Gedung B"},
		RoomCount:     2,
		TotalCapacity: 40,
		Rooms: []building.RoomSummary{
			{ID: id, Name: "R.101", Capacity: 20},
			{ID: uuid.New(), Name: "R.102", Capacity: 20},
		},
	}
	if b.RoomCount != 2 {
		t.Errorf("expected 2, got %d", b.RoomCount)
	}
	if b.TotalCapacity != 40 {
		t.Errorf("expected 40, got %d", b.TotalCapacity)
	}
	if b.Rooms[0].Name != "R.101" {
		t.Errorf("expected R.101, got %s", b.Rooms[0].Name)
	}
}
```

- [ ] **Step 2: Run test — expect compile error**

```bash
cd api && go test ./internal/domain/building/... 2>&1 | head -20
```
Expected: `undefined: building.BuildingWithRooms`

- [ ] **Step 3: Add types and interface to building.go**

In `api/internal/domain/building/building.go`, add after the `Building` struct:

```go
type RoomSummary struct {
	ID       uuid.UUID
	Name     string
	Capacity int
}

type BuildingWithRooms struct {
	Building
	RoomCount     int
	TotalCapacity int
	Rooms         []RoomSummary
}
```

Update `ReadRepository` interface:

```go
type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Building, error)
	List(ctx context.Context, offset, limit int) ([]*Building, int, error)
	ListWithRooms(ctx context.Context, offset, limit int, search string) ([]BuildingWithRooms, int, error)
}
```

- [ ] **Step 4: Run test — expect pass**

```bash
cd api && go test ./internal/domain/building/... -v
```
Expected: all tests PASS

- [ ] **Step 5: Verify build (interface not yet implemented)**

```bash
cd api && go build ./... 2>&1 | head -20
```
Expected: compile error about `BuildingRepository` not implementing `ReadRepository` (missing `ListWithRooms`). This confirms the interface change propagated.

- [ ] **Step 6: Commit**

```bash
cd api && git add internal/domain/building/building.go internal/domain/building/building_test.go
git commit -m "feat(building): add RoomSummary, BuildingWithRooms types and ListWithRooms interface"
```

---

## Task 2: Query — Add Search field to ListBuildingsQuery

**Files:**
- Modify: `api/internal/query/list_buildings/query.go`

- [ ] **Step 1: Update query.go**

Replace content of `api/internal/query/list_buildings/query.go`:

```go
package list_buildings

type ListBuildingsQuery struct {
	Offset int
	Limit  int
	Search string
}
```

- [ ] **Step 2: Verify compile**

```bash
cd api && go build ./internal/query/list_buildings/... 2>&1
```
Expected: no errors (handler still compiles even though it doesn't use Search yet)

- [ ] **Step 3: Commit**

```bash
cd api && git add internal/query/list_buildings/query.go
git commit -m "feat(list-buildings): add Search field to ListBuildingsQuery"
```

---

## Task 3: Repository — Implement ListWithRooms

**Files:**
- Modify: `api/infrastructure/database/building_repository.go`

- [ ] **Step 1: Add new row struct and implement ListWithRooms**

In `api/infrastructure/database/building_repository.go`, add after the `buildingRow` struct:

```go
type buildingWithRoomsRow struct {
	ID            string    `db:"id"`
	Name          string    `db:"name"`
	Address       string    `db:"address"`
	Description   string    `db:"description"`
	CreatedAt     time.Time `db:"created_at"`
	UpdatedAt     time.Time `db:"updated_at"`
	RoomCount     int       `db:"room_count"`
	TotalCapacity int       `db:"total_capacity"`
	RoomsJSON     []byte    `db:"rooms"`
}

type roomSummaryJSON struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Capacity int    `json:"capacity"`
}
```

Add method to `BuildingRepository` (after the `List` method):

```go
func (r *BuildingRepository) ListWithRooms(ctx context.Context, offset, limit int, search string) ([]building.BuildingWithRooms, int, error) {
	var total int
	countQuery := `
		SELECT COUNT(DISTINCT b.id)
		FROM buildings b
		WHERE ($1 = '' OR b.name ILIKE '%' || $1 || '%' OR b.address ILIKE '%' || $1 || '%')
	`
	if err := r.db.GetContext(ctx, &total, countQuery, search); err != nil {
		return nil, 0, fmt.Errorf("failed to count buildings: %w", err)
	}

	query := `
		SELECT
			b.id, b.name, b.address, b.description, b.created_at, b.updated_at,
			COUNT(rm.id)::int AS room_count,
			COALESCE(SUM(rm.capacity), 0)::int AS total_capacity,
			COALESCE(
				json_agg(
					json_build_object('id', rm.id::text, 'name', rm.name, 'capacity', COALESCE(rm.capacity, 0))
					ORDER BY rm.name
				) FILTER (WHERE rm.id IS NOT NULL),
				'[]'::json
			) AS rooms
		FROM buildings b
		LEFT JOIN rooms rm ON rm.building_id = b.id
		WHERE ($3 = '' OR b.name ILIKE '%' || $3 || '%' OR b.address ILIKE '%' || $3 || '%')
		GROUP BY b.id, b.name, b.address, b.description, b.created_at, b.updated_at
		ORDER BY b.name ASC
		LIMIT $1 OFFSET $2
	`
	var rows []buildingWithRoomsRow
	if err := r.db.SelectContext(ctx, &rows, query, limit, offset, search); err != nil {
		return nil, 0, fmt.Errorf("failed to list buildings with rooms: %w", err)
	}

	result := make([]building.BuildingWithRooms, 0, len(rows))
	for _, row := range rows {
		id, err := uuid.Parse(row.ID)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to parse building id: %w", err)
		}

		var roomsData []roomSummaryJSON
		if len(row.RoomsJSON) > 0 {
			if err := json.Unmarshal(row.RoomsJSON, &roomsData); err != nil {
				return nil, 0, fmt.Errorf("failed to unmarshal rooms: %w", err)
			}
		}

		rooms := make([]building.RoomSummary, 0, len(roomsData))
		for _, rd := range roomsData {
			rid, err := uuid.Parse(rd.ID)
			if err != nil {
				continue
			}
			rooms = append(rooms, building.RoomSummary{
				ID:       rid,
				Name:     rd.Name,
				Capacity: rd.Capacity,
			})
		}

		result = append(result, building.BuildingWithRooms{
			Building: building.Building{
				ID:          id,
				Name:        row.Name,
				Address:     row.Address,
				Description: row.Description,
				CreatedAt:   row.CreatedAt,
				UpdatedAt:   row.UpdatedAt,
			},
			RoomCount:     row.RoomCount,
			TotalCapacity: row.TotalCapacity,
			Rooms:         rooms,
		})
	}
	return result, total, nil
}
```

Add `"encoding/json"` to the import block.

- [ ] **Step 2: Verify compile**

```bash
cd api && go build ./infrastructure/database/... 2>&1
```
Expected: no errors

- [ ] **Step 3: Verify full build — interface now satisfied**

```bash
cd api && go build ./... 2>&1 | head -20
```
Expected: no errors (BuildingRepository now implements full ReadRepository)

- [ ] **Step 4: Commit**

```bash
cd api && git add infrastructure/database/building_repository.go
git commit -m "feat(building-repo): implement ListWithRooms with room aggregation and search"
```

---

## Task 4: Handler — Use ListWithRooms, update BuildingListItem

**Files:**
- Modify: `api/internal/query/list_buildings/handler.go`

- [ ] **Step 1: Rewrite handler.go**

Replace full content of `api/internal/query/list_buildings/handler.go`:

```go
package list_buildings

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
)

type RoomItem struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Capacity int    `json:"capacity"`
}

type BuildingListItem struct {
	ID            uuid.UUID  `json:"id"`
	Name          string     `json:"name"`
	Address       string     `json:"address"`
	Description   string     `json:"description"`
	RoomCount     int        `json:"room_count"`
	TotalCapacity int        `json:"total_capacity"`
	Rooms         []RoomItem `json:"rooms"`
	CreatedAt     int64      `json:"created_at"`
	UpdatedAt     int64      `json:"updated_at"`
}

type ListBuildingsResult struct {
	Data  []*BuildingListItem `json:"data"`
	Total int                 `json:"total"`
}

type Handler struct {
	buildingReadRepo building.ReadRepository
}

func NewHandler(buildingReadRepo building.ReadRepository) *Handler {
	return &Handler{buildingReadRepo: buildingReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListBuildingsQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	limit := q.Limit
	if limit == 0 {
		limit = 20
	}

	buildings, total, err := h.buildingReadRepo.ListWithRooms(ctx, q.Offset, limit, q.Search)
	if err != nil {
		log.Error().Err(err).Msg("failed to list buildings")
		return nil, err
	}

	items := make([]*BuildingListItem, 0, len(buildings))
	for _, b := range buildings {
		rooms := make([]RoomItem, 0, len(b.Rooms))
		for _, r := range b.Rooms {
			rooms = append(rooms, RoomItem{
				ID:       r.ID.String(),
				Name:     r.Name,
				Capacity: r.Capacity,
			})
		}
		items = append(items, &BuildingListItem{
			ID:            b.ID,
			Name:          b.Name,
			Address:       b.Address,
			Description:   b.Description,
			RoomCount:     b.RoomCount,
			TotalCapacity: b.TotalCapacity,
			Rooms:         rooms,
			CreatedAt:     b.CreatedAt.Unix(),
			UpdatedAt:     b.UpdatedAt.Unix(),
		})
	}

	return &ListBuildingsResult{Data: items, Total: total}, nil
}
```

- [ ] **Step 2: Verify compile**

```bash
cd api && go build ./internal/query/list_buildings/... 2>&1
```
Expected: no errors

- [ ] **Step 3: Run all tests**

```bash
cd api && go test ./... 2>&1 | tail -20
```
Expected: all PASS (no tests broken)

- [ ] **Step 4: Commit**

```bash
cd api && git add internal/query/list_buildings/handler.go
git commit -m "feat(list-buildings): include room_count, total_capacity, and rooms in response"
```

---

## Task 5: HTTP Handler — Parse ?search= param

**Files:**
- Modify: `api/internal/delivery/http/location_handler.go`

- [ ] **Step 1: Update ListBuildings handler to parse search param**

Find the `ListBuildings` function (lines ~81-95). Replace it:

```go
func (h *LocationHandler) ListBuildings(w http.ResponseWriter, r *http.Request) {
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit == 0 {
		limit = 20
	}
	search := r.URL.Query().Get("search")

	result, err := h.qryBus.Execute(r.Context(), &listbuildings.ListBuildingsQuery{
		Offset: offset,
		Limit:  limit,
		Search: search,
	})
	if err != nil {
		log.Error().Err(err).Msg("failed to list buildings")
		writeError(w, http.StatusInternalServerError, "failed to list buildings")
		return
	}
	writeJSON(w, http.StatusOK, result)
}
```

- [ ] **Step 2: Verify compile + tests**

```bash
cd api && go build ./... && go test ./... 2>&1 | tail -10
```
Expected: build success, all tests PASS

- [ ] **Step 3: Commit**

```bash
cd api && git add internal/delivery/http/location_handler.go
git commit -m "feat(location-handler): parse ?search= param for list buildings"
```

---

## Task 6: DataTable — Add expandedRow prop

**Files:**
- Modify: `web-dashboard/src/widgets/DataTable/DataTable.tsx`

- [ ] **Step 1: Add expandedRow to DataTableProps interface**

In `DataTable.tsx`, find `interface DataTableProps<T>` (line ~52). Add after the `onExportPDF` line:

```ts
/** When provided, rows become expandable. Clicking the chevron toggles an extra row below. */
expandedRow?: (row: T) => React.ReactNode
```

- [ ] **Step 2: Add expandedRowId state**

In the `DataTable` function body (after the destructured props), add:

```ts
const [expandedRowId, setExpandedRowId] = useState<string | null>(null)
```

- [ ] **Step 3: Add chevron column when expandedRow provided**

Find where `initialColumns` is processed. Add after the `const [selectable...]` or similar local column processing:

```ts
const columns = expandedRow
  ? [
      {
        key: '__expand__',
        header: '',
        width: 40,
        render: (_v: unknown, row: T) => {
          const rowId = typeof rowKey === 'function' ? rowKey(row) : String(row[rowKey ?? 'id'])
          const isOpen = expandedRowId === rowId
          return (
            <button
              onClick={(e) => {
                e.stopPropagation()
                setExpandedRowId(isOpen ? null : rowId)
              }}
              style={{
                background: 'none', border: 'none', cursor: 'pointer',
                color: 'var(--color-text-secondary)', padding: '2px 4px',
                display: 'flex', alignItems: 'center',
                transition: 'transform 0.15s',
                transform: isOpen ? 'rotate(90deg)' : 'rotate(0deg)',
              }}
            >
              <ChevronRight size={16} />
            </button>
          )
        },
      } as ColumnDef<T>,
      ...initialColumns,
    ]
  : initialColumns
```

Note: ensure `ChevronRight` is imported from `lucide-react`. Check the existing imports at the top of `DataTable.tsx` and add `ChevronRight` if not present.

- [ ] **Step 4: Render expanded row in tbody**

Find the `<tbody>` section where rows are rendered. The pattern is `{data.map((row) => (<tr key=...>...</tr>))}`. Wrap each row in a Fragment and add the expansion row:

```tsx
{data.map((row) => {
  const rowId = typeof rowKey === 'function'
    ? rowKey(row)
    : String(row[rowKey ?? 'id'])
  const isExpanded = expandedRow !== undefined && expandedRowId === rowId

  return (
    <React.Fragment key={rowId}>
      <tr
        className={...} // keep existing className logic
        onClick={onRowClick ? () => onRowClick(row) : undefined}
      >
        {/* existing cell rendering */}
      </tr>
      {isExpanded && expandedRow && (
        <tr>
          <td
            colSpan={columns.length + (rowActions.length > 0 ? 1 : 0) + (selectable ? 1 : 0)}
            style={{ padding: 0, background: 'var(--color-surface-alt)', borderBottom: '1px solid var(--color-border)' }}
          >
            {expandedRow(row)}
          </td>
        </tr>
      )}
    </React.Fragment>
  )
})}
```

**Important:** Before editing, read lines 200–350 of `DataTable.tsx` to find the exact tbody/row rendering code and adapt the Fragment wrapper to the existing structure precisely.

- [ ] **Step 5: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep -i "DataTable\|expandedRow" | head -20
```
Expected: no errors related to DataTable

- [ ] **Step 6: Commit**

```bash
cd web-dashboard && git add src/widgets/DataTable/DataTable.tsx
git commit -m "feat(DataTable): add expandedRow prop for accordion rows"
```

---

## Task 7: ListPageTemplate — Thread expandedRow prop

**Files:**
- Modify: `web-dashboard/src/widgets/ListPageTemplate/ListPageTemplate.tsx`

- [ ] **Step 1: Add expandedRow to ListPageTemplateProps**

In `ListPageTemplate.tsx`, find `interface ListPageTemplateProps<T>` (around line 35). Add:

```ts
/** When provided, each row gets a chevron toggle. Clicking shows the returned content below the row. */
expandedRow?: (row: T) => React.ReactNode
```

- [ ] **Step 2: Destructure expandedRow in component**

In the function signature destructuring (around line 84), add `expandedRow` to the destructured props.

- [ ] **Step 3: Pass to DataTable**

In the `<DataTable<T>` JSX (around line 246), add:

```tsx
expandedRow={expandedRow}
```

- [ ] **Step 4: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep -i "ListPageTemplate\|expandedRow" | head -10
```
Expected: no errors

- [ ] **Step 5: Commit**

```bash
cd web-dashboard && git add src/widgets/ListPageTemplate/ListPageTemplate.tsx
git commit -m "feat(ListPageTemplate): thread expandedRow prop to DataTable"
```

---

## Task 8: Service — Add search param to listBuildings

**Files:**
- Modify: `web-dashboard/src/services/location.service.ts`

- [ ] **Step 1: Update listBuildings to accept params**

Replace `listBuildings` in `location.service.ts`:

```ts
listBuildings: (params?: { search?: string; offset?: number; limit?: number }) => {
  const qs = new URLSearchParams()
  if (params?.search) qs.set('search', params.search)
  if (params?.offset !== undefined) qs.set('offset', String(params.offset))
  if (params?.limit !== undefined) qs.set('limit', String(params.limit))
  const query = qs.toString() ? `?${qs}` : ''
  return apiClient.get<any>(`/buildings${query}`).then(r => (r as any).data ?? r)
},
```

- [ ] **Step 2: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "location.service" | head -10
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
cd web-dashboard && git add src/services/location.service.ts
git commit -m "feat(location-service): add search/offset/limit params to listBuildings"
```

---

## Task 9: LocationListPage — Fix all issues

**Files:**
- Modify: `web-dashboard/src/pages/Operations/LocationListPage.tsx`

- [ ] **Step 1: Rewrite LocationListPage.tsx**

Replace full content:

```tsx
import { Building2, DoorOpen, ChevronDown } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef } from '@/widgets/DataTable/DataTable'
import { locationService } from '@/services/location.service'

interface RoomItem {
  id: string
  name: string
  capacity: number
}

interface Building {
  id: string
  name: string
  address?: string
  room_count: number
  total_capacity: number
  rooms: RoomItem[]
  [key: string]: unknown
}

const columns: ColumnDef<Building>[] = [
  {
    key: 'name',
    header: 'Nama Gedung',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Building2 size={16} />
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.name || '—'}</div>
          {row.address && (
            <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
              {row.address.length > 60 ? row.address.slice(0, 60) + '...' : row.address}
            </div>
          )}
        </div>
      </div>
    ),
  },
  {
    key: 'room_count',
    header: 'Jumlah Ruangan',
    width: 140,
    align: 'center',
    render: (_v, row) => {
      const count = row.room_count ?? 0
      return count > 0
        ? (
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 4,
            padding: '2px 10px', borderRadius: 'var(--radius-full)',
            background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
            fontSize: 'var(--font-sm)', fontWeight: 600,
          }}>
            {count} ruangan
          </span>
        )
        : <span style={{ color: 'var(--color-text-tertiary)' }}>—</span>
    },
  },
  {
    key: 'total_capacity',
    header: 'Total Kapasitas',
    width: 150,
    align: 'center',
    render: (_v, row) => {
      const cap = row.total_capacity ?? 0
      return cap > 0
        ? <span style={{ fontWeight: 500 }}>{cap} orang</span>
        : <span style={{ color: 'var(--color-text-tertiary)' }}>—</span>
    },
  },
]

function RoomList({ rooms }: { rooms: RoomItem[] }) {
  if (rooms.length === 0) {
    return (
      <div style={{ padding: '12px 16px 12px 56px', color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>
        Belum ada ruangan
      </div>
    )
  }
  return (
    <div style={{ padding: '8px 16px 12px 56px' }}>
      <ul style={{ margin: 0, padding: 0, listStyle: 'none', display: 'flex', flexDirection: 'column', gap: 6 }}>
        {rooms.map((room) => (
          <li key={room.id} style={{
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '6px 12px', borderRadius: 6,
            background: 'var(--color-surface)', fontSize: 'var(--font-sm)',
          }}>
            <DoorOpen size={14} style={{ color: 'var(--color-text-secondary)', flexShrink: 0 }} />
            <span style={{ fontWeight: 500 }}>{room.name}</span>
            {room.capacity > 0 && (
              <span style={{
                marginLeft: 'auto', color: 'var(--color-text-secondary)',
                fontSize: 'var(--font-xs)',
              }}>
                {room.capacity} orang
              </span>
            )}
          </li>
        ))}
      </ul>
    </div>
  )
}

export default function LocationListPage() {
  const navigate = useNavigate()

  return (
    <ListPageTemplate<Building>
      title="Lokasi & Gedung"
      queryKey="locations/buildings"
      fetcher={async (params) => {
        const data = await locationService.listBuildings({
          search: params.search,
          offset: params.offset,
          limit: params.limit,
        })
        const items: Building[] = Array.isArray(data)
          ? data
          : (data as any)?.data ?? (data as any)?.items ?? []
        const total = (data as any)?.total ?? items.length
        return { items, total, limit: params.limit ?? 9999, offset: params.offset ?? 0 }
      }}
      columns={columns}
      hidePagination
      searchPlaceholder="Cari gedung atau alamat..."
      exportFilename="lokasi"
      emptyTitle="Belum ada gedung"
      emptyDescription="Tambahkan gedung dan ruangan untuk mengelola lokasi pelatihan."
      helpTitle="Lokasi & Gedung"
      helpText="Kelola gedung dan ruangan yang digunakan untuk pelaksanaan kursus. Setiap ruangan memiliki kapasitas dan fasilitas yang bisa dicocokkan dengan kebutuhan sesi."
      onAdd={() => navigate('/pengembangan/locations/new')}
      addLabel="Tambah Gedung"
      onRowClick={row => navigate(`/pengembangan/locations/${row.id}`)}
      expandedRow={(row) => <RoomList rooms={row.rooms ?? []} />}
    />
  )
}
```

- [ ] **Step 2: TypeScript check — full project**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -30
```
Expected: 0 errors

- [ ] **Step 3: Start dev server and verify manually**

```bash
cd web-dashboard && npm run dev &
```

Open http://localhost:3001, navigate to Lokasi & Gedung page. Verify:
- [ ] Kolom "Jumlah Ruangan" shows badge with count (or "—" if no rooms)
- [ ] Kolom "Total Kapasitas" shows "X orang" (or "—")
- [ ] No "Fasilitas" column
- [ ] Chevron appears on each row (leftmost column)
- [ ] Clicking chevron expands to show room list
- [ ] Clicking row navigates to detail page
- [ ] Search box filters results from server

- [ ] **Step 4: Commit**

```bash
cd web-dashboard && git add src/pages/Operations/LocationListPage.tsx
git commit -m "feat(location-list): fix empty columns, remove facilities, fix search, add room accordion"
```

---

## Final Verification

- [ ] **Step 1: Full API test suite**

```bash
cd api && go test ./... 2>&1 | tail -10
```
Expected: all PASS

- [ ] **Step 2: Full frontend type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -10
```
Expected: 0 errors

- [ ] **Step 3: Update wolf memory**

Append to `.wolf/memory.md`:
```
| HH:MM | Fix LocationListPage: room count/capacity, search, accordion, remove facilities | 9 files | complete | ~3500 |
```

Update `.wolf/cerebrum.md` Key Learnings:
- `list_buildings/handler.go` response did NOT include rooms — always check backend shape when frontend columns appear empty
- `ListPageTemplate` fetcher receives `params` (with `search`) but must explicitly use them — ignore = silent no-op
- `DataTable` has no built-in expandable rows — add via `expandedRow` prop pattern

---

## Notes

- `Task 6 Step 4` requires reading `DataTable.tsx` lines 200-350 before editing to find exact tbody rendering. The file is 22KB — do NOT skip this read.
- SQL `json_agg FILTER (WHERE rm.id IS NOT NULL)` prevents null entry when building has 0 rooms (LEFT JOIN produces NULL room row).
- API `limit=9999` still works — `hidePagination` keeps current behavior, server-side search narrows results before they reach client.
