# Location Ownership — Design Spec

**Date:** 2026-05-06
**Status:** Approved

---

## Goal

Add an `ownership` field to the Building entity to track whether a location is self-owned or belongs to an external partner. When partner-owned, the building links to the Partner entity.

---

## Data Model

### Migration

```sql
ALTER TABLE buildings
  ADD COLUMN ownership VARCHAR(10) NOT NULL DEFAULT 'self'
    CHECK (ownership IN ('self', 'partner')),
  ADD COLUMN partner_id UUID REFERENCES partners(id) ON DELETE SET NULL;

ALTER TABLE buildings
  ADD CONSTRAINT chk_partner_ownership
    CHECK (ownership = 'self' OR partner_id IS NOT NULL);
```

- `ownership` defaults to `'self'` — existing rows unaffected.
- `partner_id` is nullable; only required when `ownership = 'partner'`.
- `ON DELETE SET NULL`: if a partner is deleted, building reverts ownership info but keeps the record. The `chk_partner_ownership` constraint means the app must handle this edge case (set ownership back to 'self' or re-assign partner).

### Go Domain — Building struct

```go
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
```

---

## API

### Create — POST /buildings

Request body adds:
```json
{
  "name": "...",
  "address": "...",
  "description": "...",
  "ownership": "partner",
  "partner_id": "uuid-of-partner"
}
```

Validation:
- `ownership` required, must be `"self"` or `"partner"`
- `partner_id` required if and only if `ownership = "partner"`

### Update — PUT /buildings/{id}

Same fields as create. Same validation rules.

### Get — GET /buildings/{id}

Response embeds partner object when ownership = partner:

```json
{
  "id": "...",
  "name": "...",
  "address": "...",
  "description": "...",
  "ownership": "partner",
  "partner": {
    "id": "...",
    "name": "..."
  }
}
```

When `ownership = "self"`, `partner` field is omitted (or null).

### List — GET /buildings

Each building in the list includes `ownership` and `partner.name` (for display in list rows). No deep nesting beyond `{id, name}`.

---

## Frontend — Form (LocationFormPage)

### New fields

1. **Ownership radio group** — "Milik Sendiri" / "Milik Partner"
   - Default: "Milik Sendiri"
   - Shown always

2. **Partner SearchableSelect** — shown conditionally when ownership = "partner"
   - Uses existing `SearchableSelect` widget from `@/widgets/SearchableSelect`
   - `fetchOptions`: calls `GET /partners?search=<query>` → maps to `{value: id, label: name}`
   - Clears selection when switching back to "self"
   - Required when visible

### Form state additions

```ts
ownership: 'self' | 'partner'   // default 'self'
partnerId: string                // empty string when self
partnerLabel: string             // display label for SearchableSelect
```

### Edit mode

Populate ownership and partner from existing building data on load.

---

## Frontend — Detail (LocationDetailPage)

Show ownership info in the detail view:
- Badge: "Milik Sendiri" (neutral) or "Milik Partner" (info color)
- If partner-owned: show partner name as a link to `/business-dev/partners/{id}`

---

## Frontend — List (LocationListPage)

Add an "Kepemilikan" column showing ownership badge + partner name (if applicable).

---

## Scope Boundaries

- No approval workflow for ownership changes.
- No notification when a partner is deleted (the `ON DELETE SET NULL` is silent — out of scope).
- Partner dropdown shows all active partners (no filtering by group or type).
