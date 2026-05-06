# TalentPool Nav Section — Design Spec

**Date:** 2026-05-06  
**Status:** Approved

---

## Objective

Promote TalentPool from a single item inside "Pendidikan" section to its own top-level NavSection in Navbar1, with two submenu items derived from the API.

---

## API Basis

Endpoints available under tag `talentpool`:

| Method | Path | Description |
|--------|------|-------------|
| GET | `/talentpool` | List entries; filters: `status`, `master_course_id` |
| GET | `/talentpool/{id}` | Single entry |
| PUT | `/talentpool/{id}/status` | Update status: `"placed"` \| `"inactive"` |
| GET | `/departments/{id}/talentpool` | Entries by department |

Status values: `"placed"`, `"inactive"` (default/active = no status filter).

---

## Nav Structure

```
Section: talent-pool  (icon: Magnet, label: "Talent Pool")
├── "Dalam Pipeline"   path: /talentpool          status filter: none (active candidates)
└── "Ditempatkan"      path: /talentpool/placed    status filter: placed
```

Permission: `canViewTalentPool` → director, education_leader, dept_leader, course_owner.

---

## Changes Required

### 1. `navItems.ts`

- Change `pendidikan` section: `ALL_ITEMS.slice(1, 8)` → `[...ALL_ITEMS.slice(1, 6), ALL_ITEMS[7]]`
  - Removes talentpool (index 6) from Pendidikan; other section indices unaffected.
- Add `TALENTPOOL_ITEMS: NavItem[]` const (2 items) before `NAV_SECTIONS`.
- Add `talent-pool` NavSection after `pendidikan` in `NAV_SECTIONS`, using `TALENTPOOL_ITEMS`.
- Icons: section → `Magnet` (already imported); "Dalam Pipeline" → `Users`; "Ditempatkan" → `Trophy` (both already imported).

### 2. `routes.tsx`

- Add lazy import: `TalentPoolPlacedPage`
- Add route: `{ path: 'talentpool/placed', element: <S><TalentPoolPlacedPage /></S> }`
  - Place immediately after `talentpool` route.

### 3. `src/pages/TalentPool/TalentPoolPlacedPage.tsx` (new file)

- Same pattern as `TalentPoolPage.tsx`.
- Fetcher: `talentPoolService.list({ status: 'placed', ...params })`
- Title: "Ditempatkan"
- Empty state: "Belum ada kandidat yang ditempatkan."
- Same columns as TalentPoolPage (no pipeline_stage column needed — all are placed).
- Row action: Update Status (placed → inactive only).

### 4. `src/pages/TalentPool/TalentPoolPage.tsx` (minor update)

- Title stays "Dalam Pipeline" (update from "Talent Pool").
- No status filter change — shows all non-placed entries by default.
- Update `helpTitle` and `helpText` to reflect "Dalam Pipeline" context.

---

## File Impact

| File | Change |
|------|--------|
| `web-dashboard/src/layouts/AppSidebar/navItems.ts` | Modify pendidikan slice, add TALENTPOOL_ITEMS + NavSection |
| `web-dashboard/src/app/routes.tsx` | Add lazy import + route |
| `web-dashboard/src/pages/TalentPool/TalentPoolPage.tsx` | Minor title/help text update |
| `web-dashboard/src/pages/TalentPool/TalentPoolPlacedPage.tsx` | New file |

No service changes needed — `talentPoolService.list(params)` already accepts status filter.

---

## Constraints

- No changes to `ALL_ITEMS` order — only section grouping changes.
- `canViewTalentPool` function already exists; reuse as-is.
- `Magnet`, `Users`, `Trophy` all already imported in `navItems.ts`.
