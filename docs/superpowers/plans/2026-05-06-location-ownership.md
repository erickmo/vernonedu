# Location Ownership Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `ownership` (self/partner) and `partner_id` fields to the Building entity, with nested partner data in API responses and a conditional SearchableSelect in the form.

**Architecture:** DB migration → Go domain update → command/query/repo updates → HTTP handler update → frontend service + UI. Each layer builds on the previous. The GetBuilding query does a LEFT JOIN to embed partner name in the response.

**Tech Stack:** Go (Chi, sqlx, CQRS), PostgreSQL, React 18 TypeScript, SearchableSelect widget.

---

## Files Modified / Created

**Backend:**
- Create: `api/migrations/079_add_building_ownership.sql`
- Modify: `api/internal/domain/building/building.go`
- Modify: `api/internal/command/create_building/command.go`
- Modify: `api/internal/command/create_building/handler.go`
- Modify: `api/internal/command/update_building/command.go`
- Modify: `api/internal/command/update_building/handler.go`
- Modify: `api/infrastructure/database/building_repository.go`
- Modify: `api/internal/query/get_building/handler.go`
- Modify: `api/internal/delivery/http/location_handler.go`

**Frontend:**
- Modify: `web-dashboard/src/services/location.service.ts`
- Modify: `web-dashboard/src/pages/Operations/LocationFormPage.tsx`
- Modify: `web-dashboard/src/pages/Operations/LocationDetailPage.tsx`
- Modify: `web-dashboard/src/pages/Operations/LocationListPage.tsx`

---

## Task 1: DB Migration

**Files:**
- Create: `api/migrations/079_add_building_ownership.sql`

- [ ] **Step 1: Create migration file**

```sql
-- api/migrations/079_add_building_ownership.sql
ALTER TABLE buildings
  ADD COLUMN ownership VARCHAR(10) NOT NULL DEFAULT 'self'
    CHECK (ownership IN ('self', 'partner')),
  ADD COLUMN partner_id UUID REFERENCES partners(id) ON DELETE SET NULL;

ALTER TABLE buildings
  ADD CONSTRAINT chk_building_partner_ownership
    CHECK (ownership = 'self' OR partner_id IS NOT NULL);
```

- [ ] **Step 2: Run migration**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
make migrate-up
```

Expected: migration runs without error.

- [ ] **Step 3: Commit**

```bash
git add api/migrations/079_add_building_ownership.sql
git commit -m "feat(db): add ownership and partner_id to buildings table"
```

---

## Task 2: Go Domain — Building struct

**Files:**
- Modify: `api/internal/domain/building/building.go`

- [ ] **Step 1: Update Building struct and add new types**

Replace the entire `building.go` with:

```go
package building

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidName      = errors.New("building name is required")
	ErrInvalidOwnership = errors.New("ownership must be 'self' or 'partner'")
	ErrPartnerRequired  = errors.New("partner_id is required when ownership is 'partner'")
	ErrBuildingNotFound = errors.New("building not found")
)

type Building struct {
	ID          uuid.UUID
	Name        string
	Address     string
	Description string
	Ownership   string     // "self" | "partner"
	PartnerID   *uuid.UUID // nil when ownership = "self"
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type PartnerRef struct {
	ID   uuid.UUID
	Name string
}

type BuildingWithPartner struct {
	Building
	Partner *PartnerRef // nil when ownership = "self"
}

func NewBuilding(name, address, description, ownership string, partnerID *uuid.UUID) (*Building, error) {
	if name == "" {
		return nil, ErrInvalidName
	}
	if ownership != "self" && ownership != "partner" {
		return nil, ErrInvalidOwnership
	}
	if ownership == "partner" && partnerID == nil {
		return nil, ErrPartnerRequired
	}
	return &Building{
		ID:          uuid.New(),
		Name:        name,
		Address:     address,
		Description: description,
		Ownership:   ownership,
		PartnerID:   partnerID,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}, nil
}

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

type WriteRepository interface {
	Save(ctx context.Context, b *Building) error
	Update(ctx context.Context, b *Building) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Building, error)
	GetByIDWithPartner(ctx context.Context, id uuid.UUID) (*BuildingWithPartner, error)
	List(ctx context.Context, offset, limit int) ([]*Building, int, error)
	ListWithRooms(ctx context.Context, offset, limit int, search string) ([]BuildingWithRooms, int, error)
}
```

- [ ] **Step 2: Verify existing test still compiles**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
go build ./...
```

Expected: compile errors for callers of `NewBuilding` (they pass 3 args, now need 5). These will be fixed in subsequent tasks.

- [ ] **Step 3: Commit**

```bash
git add api/internal/domain/building/building.go
git commit -m "feat(building): add Ownership, PartnerID fields and BuildingWithPartner type"
```

---

## Task 3: Update create_building command

**Files:**
- Modify: `api/internal/command/create_building/command.go`
- Modify: `api/internal/command/create_building/handler.go`

- [ ] **Step 1: Update command.go**

```go
package create_building

import "github.com/google/uuid"

type CreateBuildingCommand struct {
	Name        string     `validate:"required"`
	Address     string
	Description string
	Ownership   string     `validate:"required"`
	PartnerID   *uuid.UUID
	ResultID    uuid.UUID
}
```

- [ ] **Step 2: Update handler.go**

```go
package create_building

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
	"github.com/vernonedu/entrepreneurship-api/pkg/commandbus"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

type Handler struct {
	buildingWriteRepo building.WriteRepository
	eventBus          eventbus.EventBus
}

func NewHandler(buildingWriteRepo building.WriteRepository, eventBus eventbus.EventBus) *Handler {
	return &Handler{
		buildingWriteRepo: buildingWriteRepo,
		eventBus:          eventBus,
	}
}

func (h *Handler) Handle(ctx context.Context, cmd commandbus.Command) error {
	c, ok := cmd.(*CreateBuildingCommand)
	if !ok {
		return ErrInvalidCommand
	}

	b, err := building.NewBuilding(c.Name, c.Address, c.Description, c.Ownership, c.PartnerID)
	if err != nil {
		log.Error().Err(err).Msg("failed to create building entity")
		return err
	}

	if err := h.buildingWriteRepo.Save(ctx, b); err != nil {
		log.Error().Err(err).Msg("failed to save building")
		return err
	}
	c.ResultID = b.ID

	event := &building.BuildingCreatedEvent{
		EventType:  "BuildingCreated",
		BuildingID: b.ID,
		Timestamp:  time.Now().Unix(),
	}
	if err := h.eventBus.Publish(ctx, event); err != nil {
		log.Error().Err(err).Msg("failed to publish BuildingCreated event")
		return err
	}

	log.Info().Str("building_id", b.ID.String()).Msg("building created")
	return nil
}
```

- [ ] **Step 3: Commit**

```bash
git add api/internal/command/create_building/command.go api/internal/command/create_building/handler.go
git commit -m "feat(create-building): add ownership and partner_id to command"
```

---

## Task 4: Update update_building command

**Files:**
- Modify: `api/internal/command/update_building/command.go`
- Modify: `api/internal/command/update_building/handler.go`

- [ ] **Step 1: Update command.go**

```go
package update_building

import "github.com/google/uuid"

type UpdateBuildingCommand struct {
	ID          uuid.UUID  `validate:"required"`
	Name        string     `validate:"required"`
	Address     string
	Description string
	Ownership   string     `validate:"required"`
	PartnerID   *uuid.UUID
}
```

- [ ] **Step 2: Read and update handler.go**

Read `api/internal/command/update_building/handler.go` first. Then update the `Handle` method to set `Ownership` and `PartnerID` on the building before calling `Update`:

The handler fetches the building via `buildingWriteRepo` (or directly updates). Check the existing handler — if it does a fetch-then-update pattern, add:

```go
b.Ownership  = c.Ownership
b.PartnerID  = c.PartnerID
b.UpdatedAt  = time.Now()
```

If it calls `Update` directly with a constructed `Building`, add the two fields to the constructed struct.

- [ ] **Step 3: Commit**

```bash
git add api/internal/command/update_building/command.go api/internal/command/update_building/handler.go
git commit -m "feat(update-building): add ownership and partner_id to command"
```

---

## Task 5: Update building_repository.go

**Files:**
- Modify: `api/infrastructure/database/building_repository.go`

- [ ] **Step 1: Update buildingRow struct**

```go
type buildingRow struct {
	ID          string    `db:"id"`
	Name        string    `db:"name"`
	Address     string    `db:"address"`
	Description string    `db:"description"`
	Ownership   string    `db:"ownership"`
	PartnerID   *string   `db:"partner_id"`
	CreatedAt   time.Time `db:"created_at"`
	UpdatedAt   time.Time `db:"updated_at"`
}
```

- [ ] **Step 2: Update toDomain()**

```go
func (row *buildingRow) toDomain() (*building.Building, error) {
	id, err := uuid.Parse(row.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to parse building id: %w", err)
	}
	b := &building.Building{
		ID:          id,
		Name:        row.Name,
		Address:     row.Address,
		Description: row.Description,
		Ownership:   row.Ownership,
		CreatedAt:   row.CreatedAt,
		UpdatedAt:   row.UpdatedAt,
	}
	if row.PartnerID != nil {
		pid, err := uuid.Parse(*row.PartnerID)
		if err == nil {
			b.PartnerID = &pid
		}
	}
	return b, nil
}
```

- [ ] **Step 3: Update Save()**

```go
func (r *BuildingRepository) Save(ctx context.Context, b *building.Building) error {
	query := `
		INSERT INTO buildings (id, name, address, description, ownership, partner_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	var partnerID interface{}
	if b.PartnerID != nil {
		partnerID = b.PartnerID.String()
	}
	_, err := r.db.ExecContext(ctx, query,
		b.ID.String(), b.Name, b.Address, b.Description,
		b.Ownership, partnerID, b.CreatedAt, b.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to save building: %w", err)
	}
	return nil
}
```

- [ ] **Step 4: Update Update()**

```go
func (r *BuildingRepository) Update(ctx context.Context, b *building.Building) error {
	query := `
		UPDATE buildings
		SET name=$1, address=$2, description=$3, ownership=$4, partner_id=$5, updated_at=$6
		WHERE id=$7
	`
	var partnerID interface{}
	if b.PartnerID != nil {
		partnerID = b.PartnerID.String()
	}
	_, err := r.db.ExecContext(ctx, query,
		b.Name, b.Address, b.Description, b.Ownership, partnerID, b.UpdatedAt, b.ID.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to update building: %w", err)
	}
	return nil
}
```

- [ ] **Step 5: Update GetByID() SELECT query**

```go
func (r *BuildingRepository) GetByID(ctx context.Context, id uuid.UUID) (*building.Building, error) {
	var row buildingRow
	query := `SELECT id, name, address, description, ownership, partner_id, created_at, updated_at FROM buildings WHERE id=$1`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get building: %w", err)
	}
	return row.toDomain()
}
```

- [ ] **Step 6: Add GetByIDWithPartner()**

```go
type buildingWithPartnerRow struct {
	buildingRow
	PartnerName *string `db:"partner_name"`
}

func (r *BuildingRepository) GetByIDWithPartner(ctx context.Context, id uuid.UUID) (*building.BuildingWithPartner, error) {
	var row buildingWithPartnerRow
	query := `
		SELECT b.id, b.name, b.address, b.description, b.ownership, b.partner_id,
		       b.created_at, b.updated_at, p.name AS partner_name
		FROM buildings b
		LEFT JOIN partners p ON p.id = b.partner_id
		WHERE b.id = $1
	`
	if err := r.db.GetContext(ctx, &row, query, id.String()); err != nil {
		return nil, fmt.Errorf("failed to get building with partner: %w", err)
	}
	b, err := row.buildingRow.toDomain()
	if err != nil {
		return nil, err
	}
	result := &building.BuildingWithPartner{Building: *b}
	if b.PartnerID != nil && row.PartnerName != nil {
		result.Partner = &building.PartnerRef{
			ID:   *b.PartnerID,
			Name: *row.PartnerName,
		}
	}
	return result, nil
}
```

- [ ] **Step 7: Update ListWithRooms() to include ownership + partner_name**

Add `b.ownership, b.partner_id, p.name AS partner_name` to the SELECT and LEFT JOIN partners. Update `buildingWithRoomsRow` to include:
```go
Ownership   string  `db:"ownership"`
PartnerID   *string `db:"partner_id"`
PartnerName *string `db:"partner_name"`
```

Update the result mapping to set `Ownership`, `PartnerID` on each `building.Building`.

- [ ] **Step 8: Compile check**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
go build ./...
```

- [ ] **Step 9: Commit**

```bash
git add api/infrastructure/database/building_repository.go
git commit -m "feat(building-repo): add ownership and partner_id to all queries"
```

---

## Task 6: Update get_building query handler

**Files:**
- Modify: `api/internal/query/get_building/handler.go`

- [ ] **Step 1: Update BuildingReadModel and handler**

```go
package get_building

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/building"
)

type PartnerSummary struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type BuildingReadModel struct {
	ID          uuid.UUID       `json:"id"`
	Name        string          `json:"name"`
	Address     string          `json:"address"`
	Description string          `json:"description"`
	Ownership   string          `json:"ownership"`
	Partner     *PartnerSummary `json:"partner,omitempty"`
	CreatedAt   int64           `json:"created_at"`
	UpdatedAt   int64           `json:"updated_at"`
}

type Handler struct {
	buildingReadRepo building.ReadRepository
}

func NewHandler(buildingReadRepo building.ReadRepository) *Handler {
	return &Handler{buildingReadRepo: buildingReadRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetBuildingQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	bwp, err := h.buildingReadRepo.GetByIDWithPartner(ctx, q.ID)
	if err != nil {
		log.Error().Err(err).Str("building_id", q.ID.String()).Msg("failed to get building")
		return nil, err
	}

	rm := &BuildingReadModel{
		ID:          bwp.ID,
		Name:        bwp.Name,
		Address:     bwp.Address,
		Description: bwp.Description,
		Ownership:   bwp.Ownership,
		CreatedAt:   bwp.CreatedAt.Unix(),
		UpdatedAt:   bwp.UpdatedAt.Unix(),
	}
	if bwp.Partner != nil {
		rm.Partner = &PartnerSummary{
			ID:   bwp.Partner.ID.String(),
			Name: bwp.Partner.Name,
		}
	}
	return rm, nil
}
```

- [ ] **Step 2: Compile + run tests**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
go build ./...
go test ./internal/query/get_building/...
```

- [ ] **Step 3: Commit**

```bash
git add api/internal/query/get_building/handler.go
git commit -m "feat(get-building): include ownership and nested partner in read model"
```

---

## Task 7: Update HTTP handler (location_handler.go)

**Files:**
- Modify: `api/internal/delivery/http/location_handler.go`

- [ ] **Step 1: Update CreateBuildingRequest**

```go
type CreateBuildingRequest struct {
	Name        string  `json:"name" validate:"required"`
	Address     string  `json:"address"`
	Description string  `json:"description"`
	Ownership   string  `json:"ownership" validate:"required"`
	PartnerID   *string `json:"partner_id"`
}
```

- [ ] **Step 2: Update UpdateBuildingRequest**

```go
type UpdateBuildingRequest struct {
	Name        string  `json:"name" validate:"required"`
	Address     string  `json:"address"`
	Description string  `json:"description"`
	Ownership   string  `json:"ownership" validate:"required"`
	PartnerID   *string `json:"partner_id"`
}
```

- [ ] **Step 3: Update CreateBuilding handler — parse partner_id + build command**

In `CreateBuilding`, after decoding request, before building the command:

```go
// Validate ownership
if req.Ownership != "self" && req.Ownership != "partner" {
    writeError(w, http.StatusBadRequest, "ownership must be 'self' or 'partner'")
    return
}
if req.Ownership == "partner" && (req.PartnerID == nil || *req.PartnerID == "") {
    writeError(w, http.StatusBadRequest, "partner_id is required when ownership is 'partner'")
    return
}

var partnerID *uuid.UUID
if req.PartnerID != nil && *req.PartnerID != "" {
    pid, err := uuid.Parse(*req.PartnerID)
    if err != nil {
        writeError(w, http.StatusBadRequest, "invalid partner_id")
        return
    }
    partnerID = &pid
}

cmd := &createbuilding.CreateBuildingCommand{
    Name:        req.Name,
    Address:     req.Address,
    Description: req.Description,
    Ownership:   req.Ownership,
    PartnerID:   partnerID,
}
```

- [ ] **Step 4: Update UpdateBuilding handler — same partner_id logic**

Apply the same ownership validation + partner_id parsing to `UpdateBuilding`, then build:

```go
cmd := &updatebuilding.UpdateBuildingCommand{
    ID:          id,
    Name:        req.Name,
    Address:     req.Address,
    Description: req.Description,
    Ownership:   req.Ownership,
    PartnerID:   partnerID,
}
```

- [ ] **Step 5: Compile**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
go build ./...
```

- [ ] **Step 6: Commit**

```bash
git add api/internal/delivery/http/location_handler.go
git commit -m "feat(location-handler): accept ownership and partner_id in create/update"
```

---

## Task 8: Frontend — location.service.ts

**Files:**
- Modify: `web-dashboard/src/services/location.service.ts`

- [ ] **Step 1: Read the file, update createBuilding and updateBuilding types**

The service currently has an untyped `create: (data: any)` and `update: (id, data)`. No change needed in service — caller passes the payload including `ownership` and `partner_id`. The service already uses `apiClient.post` and `apiClient.put` with `data: any`.

Verify current service passes `data` directly. If yes, **no change needed** — skip to commit.

If create/update have typed payloads, add:
```ts
ownership: string
partner_id?: string | null
```

- [ ] **Step 2: Commit if changed**

```bash
git add web-dashboard/src/services/location.service.ts
git commit -m "feat(location-service): support ownership and partner_id in create/update"
```

---

## Task 9: Frontend — LocationFormPage

**Files:**
- Modify: `web-dashboard/src/pages/Operations/LocationFormPage.tsx`

- [ ] **Step 1: Add imports**

Add to the existing imports:
```tsx
import { SearchableSelect, type SelectOption } from '@/widgets/SearchableSelect/SearchableSelect'
import { partnerService } from '@/services/partner.service'
```

- [ ] **Step 2: Add ownership state variables** (near existing state declarations)

```tsx
const [ownership, setOwnership] = useState<'self' | 'partner'>('self')
const [partnerId, setPartnerId] = useState('')
const [partnerLabel, setPartnerLabel] = useState('')
```

- [ ] **Step 3: Populate on edit** — add to the `useEffect` that sets form values from `building`:

```tsx
setOwnership((building as any).ownership ?? 'self')
const pid = (building as any).partner?.id ?? ''
const pname = (building as any).partner?.name ?? ''
setPartnerId(pid)
setPartnerLabel(pname)
```

- [ ] **Step 4: Update validation** — add to the validate function:

```tsx
if (ownership === 'partner' && !partnerId) {
  newErrors.partner_id = 'Partner wajib dipilih'
}
```

- [ ] **Step 5: Update submit payload** — add to the submit object sent to `locationService.createBuilding` / `locationService.updateBuilding`:

```tsx
ownership,
partner_id: ownership === 'partner' ? partnerId : null,
```

- [ ] **Step 6: Add form fields to JSX** — add after the Description field:

```tsx
<Field label="Kepemilikan" required>
  <div style={{ display: 'flex', gap: 'var(--space-4)' }}>
    {(['self', 'partner'] as const).map((opt) => (
      <label key={opt} style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
        <input
          type="radio"
          name="ownership"
          value={opt}
          checked={ownership === opt}
          onChange={() => {
            setOwnership(opt)
            if (opt === 'self') { setPartnerId(''); setPartnerLabel('') }
          }}
        />
        {opt === 'self' ? 'Milik Sendiri' : 'Milik Partner'}
      </label>
    ))}
  </div>
</Field>

{ownership === 'partner' && (
  <Field label="Partner" required error={errors.partner_id}>
    <SearchableSelect
      value={partnerId}
      displayLabel={partnerLabel}
      placeholder="Cari partner..."
      fetchOptions={async (search) => {
        const res = await partnerService.list({ search, limit: 20 })
        return (res.items ?? []).map((p: any) => ({
          value: p.id,
          label: p.name,
        }))
      }}
      onSelect={(opt) => {
        setPartnerId(opt?.value ?? '')
        setPartnerLabel(opt?.label ?? '')
      }}
    />
  </Field>
)}
```

- [ ] **Step 7: Commit**

```bash
git add web-dashboard/src/pages/Operations/LocationFormPage.tsx
git commit -m "feat(location-form): add ownership radio and conditional partner SearchableSelect"
```

---

## Task 10: Frontend — LocationDetailPage

**Files:**
- Modify: `web-dashboard/src/pages/Operations/LocationDetailPage.tsx`

- [ ] **Step 1: Add ownership badge + partner link to the detail view**

Read the file. Find where building info is displayed (likely in the sections/tabs content). Add an ownership section. After the existing building data display, add:

```tsx
{/* Ownership info — add inside the detail content area */}
<div style={{ display: 'flex', gap: 'var(--space-3)', marginBottom: 'var(--space-3)' }}>
  <span style={{
    display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
    fontSize: 'var(--font-xs)', fontWeight: 600,
    background: b?.ownership === 'partner' ? 'var(--color-info-light)' : 'var(--color-surface-alt)',
    color: b?.ownership === 'partner' ? 'var(--color-info-dark)' : 'var(--color-text-secondary)',
  }}>
    {b?.ownership === 'partner' ? 'Milik Partner' : 'Milik Sendiri'}
  </span>
</div>
{b?.partner && (
  <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
    Partner:{' '}
    <a
      href={`/business-dev/partners/${b.partner.id}`}
      style={{ color: 'var(--color-primary)', fontWeight: 600 }}
    >
      {b.partner.name}
    </a>
  </div>
)}
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/pages/Operations/LocationDetailPage.tsx
git commit -m "feat(location-detail): show ownership badge and partner link"
```

---

## Task 11: Frontend — LocationListPage

**Files:**
- Modify: `web-dashboard/src/pages/Operations/LocationListPage.tsx`

- [ ] **Step 1: Add ownership column to the columns array**

After the `room_count` column, add:

```tsx
{
  key: 'ownership',
  header: 'Kepemilikan',
  width: 160,
  render: (_v, row: any) => (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600,
      background: row.ownership === 'partner' ? 'var(--color-info-light)' : 'var(--color-surface-alt)',
      color: row.ownership === 'partner' ? 'var(--color-info-dark)' : 'var(--color-text-secondary)',
    }}>
      {row.ownership === 'partner'
        ? (row.partner_name ? `Partner: ${row.partner_name}` : 'Milik Partner')
        : 'Milik Sendiri'}
    </span>
  ),
},
```

Note: `row.partner_name` is only available if the list API returns it. The `ListWithRooms` query will include `p.name AS partner_name` after Task 5 Step 7. The frontend reads it from `row.partner_name`.

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/pages/Operations/LocationListPage.tsx
git commit -m "feat(location-list): add ownership column with partner name"
```
