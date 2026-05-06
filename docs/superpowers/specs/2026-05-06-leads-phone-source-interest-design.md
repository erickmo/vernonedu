# Leads: Phone Mandatory + Source Entity + Interest Multi-Link

**Date:** 2026-05-06  
**Status:** Approved  
**Scope:** Lead domain — API (Go) + Frontend (React)

---

## Summary

Three changes to the Lead domain:
1. Phone field becomes mandatory (was optional)
2. Lead source becomes a managed entity (`lead_sources` table) instead of a hardcoded enum string
3. Lead interest becomes a multi-link to MasterCourse / CourseType / CourseBatch (was a free-text string)

---

## 1. Data Model

### New table: `lead_sources`

```sql
CREATE TABLE lead_sources (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL,
    is_active  BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### New table: `lead_interests`

```sql
CREATE TABLE lead_interests (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id     UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('master_course', 'course_type', 'course_batch')),
    entity_id   UUID NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lead_interests_lead_id ON lead_interests(lead_id);
```

### Alter table: `leads`

```sql
-- Drop old columns
ALTER TABLE leads DROP COLUMN interest;
ALTER TABLE leads DROP COLUMN source;

-- Add new FK column
ALTER TABLE leads ADD COLUMN source_id UUID REFERENCES lead_sources(id) ON DELETE SET NULL;
ALTER TABLE leads ADD COLUMN phone_required_check CHECK (phone <> '');
-- Also: remove DEFAULT '' from phone to enforce non-empty at DB level
ALTER TABLE leads ALTER COLUMN phone SET NOT NULL;
-- Seed default sources
INSERT INTO lead_sources (name) VALUES ('Referral'), ('Media Sosial'), ('Walk In'), ('Website'), ('Lainnya');
```

### Domain structs (Go)

```go
type LeadSource struct {
    ID        uuid.UUID
    Name      string
    IsActive  bool
    CreatedAt time.Time
    UpdatedAt time.Time
}

type LeadInterest struct {
    ID         uuid.UUID
    LeadID     uuid.UUID
    EntityType string   // "master_course" | "course_type" | "course_batch"
    EntityID   uuid.UUID
    EntityName string   // resolved at query time (JOIN or lookup)
    CreatedAt  time.Time
}

// Updated Lead — phone required, source_id FK, no interest string
type Lead struct {
    ID        uuid.UUID
    Name      string
    Email     string
    Phone     string    // required, non-empty
    SourceID  *uuid.UUID
    Notes     string
    Status    string
    PicID     *uuid.UUID
    CreatedAt time.Time
    UpdatedAt time.Time
}
```

---

## 2. API Endpoints

### Lead Sources (under `/settings/`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/settings/lead-sources` | director/admin | List all (active + inactive) |
| POST | `/settings/lead-sources` | director/admin | Create |
| PUT | `/settings/lead-sources/:id` | director/admin | Update name/is_active |
| DELETE | `/settings/lead-sources/:id` | director/admin | Soft-delete (set is_active=false if used by leads; hard delete if unused) |

### Lead Interests

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/leads/:id/interests` | staff | Add an interest |
| DELETE | `/leads/:id/interests/:interestId` | staff | Remove an interest |

Interests are returned embedded in `GET /leads/:id`.

### Lead (changes)

**POST/PUT `/leads`** — body changes:
- `phone` now required (validation error if empty)
- `source_id` uuid (nullable FK) replaces `source` string
- `interest` field removed

### GET /leads/:id response changes

```json
{
  "id": "...",
  "name": "...",
  "phone": "...",
  "email": "...",
  "source": { "id": "...", "name": "Referral" },
  "interests": [
    { "id": "...", "entity_type": "master_course", "entity_id": "...", "entity_name": "Web Development" },
    { "id": "...", "entity_type": "course_batch",  "entity_id": "...", "entity_name": "Batch Jan 2026" }
  ],
  "notes": "...",
  "status": "...",
  "created_at": 1234567890,
  "updated_at": 1234567890
}
```

### GET /leads list response changes

- `source` field: `{ "id": "...", "name": "Referral" }` or null
- `interests` field: NOT included in list (only in detail)

---

## 3. Commands & Queries

### New commands
- `create_lead_source` — name string
- `update_lead_source` — id, name, is_active
- `delete_lead_source` — id
- `add_lead_interest` — lead_id, entity_type, entity_id
- `remove_lead_interest` — lead_id, interest_id

### Updated commands
- `create_lead` — phone required (validate:"required"), source_id *uuid.UUID (optional), remove interest/source string
- `update_lead` — same changes

### New queries
- `list_lead_sources` — returns all sources with is_active flag

### Updated queries
- `get_lead` — read model includes source object + interests array (JOIN lead_sources + lead_interests with entity name lookup)
- `list_lead` — read model includes source object (JOIN lead_sources), no interests

---

## 4. Frontend

### New pages

**`/settings/lead-sources`** — `LeadSourceListPage`
- ListPageTemplate: columns Name, Status (Active/Inactive), Actions (Edit/Delete)
- Add button → `/settings/lead-sources/new`
- Row click → `/settings/lead-sources/:id/edit`

**`/settings/lead-sources/new`** and **`/settings/lead-sources/:id/edit`** — `LeadSourceFormPage`
- Fields: Name (required), Is Active (toggle, edit only)
- After save: new→list, edit→list

### Updated pages

**`LeadFormPage`**
- Phone: add required validation (`'Telepon wajib diisi'`)
- Source: change from static `<select>` to dynamic dropdown — load active sources from `GET /settings/lead-sources`
- Interest text field: removed
- Interests section added **edit form only** (below other fields, or in a second tab):
  - Type toggle: `Master Course | Course Type | Batch`
  - Searchable combobox loads entities for selected type
  - "+ Tambah" button → `POST /leads/:id/interests`
  - List of current interests as chips with `×` → `DELETE /leads/:id/interests/:interestId`

**`LeadDetailPage`**
- Source: show `source.name` (badge) instead of raw string enum
- Add Interests section: list of chips `[Type] Entity Name ×` (read-only, no ×)
- Remove Minat InfoCard with raw string

**`LeadListPage`**
- Source column: render `row.source?.name ?? '—'` instead of `SOURCE_LABELS[v]`
- Interest column: removed (replaced by interests count or omitted)

### New service

**`lead-source.service.ts`**
- `list()` — GET /settings/lead-sources
- `create(data)` — POST
- `update(id, data)` — PUT
- `delete(id)` — DELETE

### Updated service

**`lead.service.ts`**
- `create` — remove interest param, add source_id; phone always included
- `update` — same
- Add `addInterest(leadId, { entity_type, entity_id })` → POST /leads/:id/interests
- Add `removeInterest(leadId, interestId)` → DELETE /leads/:id/interests/:interestId

### Routes to add

```tsx
// Settings
const LeadSourceListPage = lazy(() => import('@/pages/Settings/LeadSourceListPage'))
const LeadSourceFormPage = lazy(() => import('@/pages/Settings/LeadSourceFormPage'))

{ path: 'settings/lead-sources',          element: <S><LeadSourceListPage /></S> },
{ path: 'settings/lead-sources/new',      element: <S><LeadSourceFormPage /></S> },
{ path: 'settings/lead-sources/:sourceId/edit', element: <S><LeadSourceFormPage /></S> },
```

---

## 5. Interest Entity Name Resolution

At query time, `lead_interests` does not store entity name — it stores `entity_type + entity_id`. The `get_lead` query handler must resolve entity names:

- `master_course` → join or query `master_courses.name`
- `course_type` → join or query `course_types.name`
- `course_batch` → join or query `course_batches.name` (or batch code)

Implementation: single SQL query with LEFT JOINs on all three tables, COALESCE for entity_name.

---

## 6. Backward Compatibility

- Existing leads: `source` column dropped, `source_id` set to NULL (existing data loses source mapping — acceptable)
- Existing leads: `interest` column dropped — existing free-text lost (acceptable, migration tradeoff)
- Frontend: `SOURCE_LABELS` map removed; source filter in list page loads dynamically from API

---

## Out of Scope

- Interest search/combobox pagination (load all active entities, sufficient for current data volume)
- Bulk interest operations
- Interest ordering/priority
