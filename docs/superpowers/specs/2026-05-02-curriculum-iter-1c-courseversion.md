# Curriculum Iter 1C — CourseVersion (Versions Tab)

**Date:** 2026-05-02
**Type:** Implementation spec (Fase 1 Curriculum, Iterasi 1C)
**Roadmap:** `docs/superpowers/specs/2026-05-02-frontend-crud-parity-roadmap.md` Bucket 1
**Predecessor:** `docs/superpowers/specs/2026-05-02-curriculum-iter-1b-coursetype.md`
**Status:** Draft → User Review

---

## §1 Purpose & Scope

### Tujuan
Aktifkan Versions tab di CourseDetail. CRUD CourseVersion per CourseType, status workflow draft→review→approved→archived.

### In-scope
- Versions tab aktif di `/internal/courses/:id` (replace placeholder)
- CourseType selector (versions adalah child dari CourseType, bukan langsung MasterCourse)
- List CourseVersion per CourseType (timeline / table)
- Create CourseVersion (auto-suggest next version dari changeType)
- Detail panel: changelog, status, approver, timestamps
- Promote action: draft→review, review→approved (with approver capture)
- Permission gate via `RoleGate` + `canAccess` (`courseversion` resource)

### Out-of-scope
- Archive UI (backend `Archive()` ada di domain tapi belum exposed via HTTP — defer ke iter berikut atau backend extension)
- Edit CourseVersion (changelog/changeType — backend tidak expose `Update`, hanya Promote)
- Inline modules editor (deferred ke Iter 1D — CourseModule)
- Propose-with-modules wizard (POST `/versions/propose`) — deferred (multi-step approval flow)
- Diff antar version

### Workflow Status
`draft` → `review` → `approved` → `archived`

Approve menghasilkan side-effect backend: semua approved version lain di CourseType yg sama otomatis di-archive (lihat `domain.WriteRepository.ArchiveAllApproved`).

### ChangeType Enum (FE)
- `major` — breaking curriculum changes
- `minor` — additive changes
- `patch` — fixes / clarifications

---

## §2 Architecture & Components

### File Map

| File | Action | Tujuan |
|---|---|---|
| `frontend/src/types/courseversion.ts` | Create | `CourseVersion`, `CourseVersionStatus`, `ChangeType` |
| `frontend/src/schemas/courseversion.ts` | Create | Zod schema + `CHANGE_TYPES`, `VERSION_STATUSES` |
| `frontend/src/schemas/__tests__/courseversion.test.ts` | Create | 6 unit tests |
| `frontend/src/lib/api/curriculum.ts` | Modify | Tambah 4 hook: list/get/create/promote |
| `frontend/src/portals/internal/components/curriculum/VersionsTab.tsx` | Create | Container — CourseType selector + version list |
| `frontend/src/portals/internal/components/curriculum/VersionTimeline.tsx` | Create | List item dengan status badge + promote button |
| `frontend/src/portals/internal/components/curriculum/VersionDetailPanel.tsx` | Create | Right panel detail + changelog |
| `frontend/src/portals/internal/components/curriculum/VersionForm.tsx` | Create | Create form (changeType + changelog) |
| `frontend/src/portals/internal/pages/detail/CourseDetail.tsx` | Modify | Render `<VersionsTab/>` saat `tab === 'versions'` |
| `frontend/src/lib/auth/permissions.ts` | Verify/Modify | Pastikan `courseversion` matrix ada |

### Komponen Shared
Reuse: `StatusBadge`, `Button`, `TextArea`, `Select`, `RoleGate`, `LoadingSpinner`, `ConfirmDialog`. No new shared component.

### Data Flow
```
VersionsTab(courseId)
  ├── useCourseTypes(courseId) → dropdown selector
  └── (selectedTypeId)
        ├── useCourseVersions(typeId) → list
        │   └── VersionTimeline (per item)
        │       ├── click → setSelectedVersionId
        │       └── promote button → usePromoteCourseVersion
        ├── VersionDetailPanel (selectedVersionId)
        │   └── useCourseVersion(versionId)
        └── VersionForm (mode=create)
              └── useCreateCourseVersion(typeId)
```

### Permission
| Action | Resource | Roles |
|---|---|---|
| `list`, `read` | `courseversion` | director, ceo, education_leader, academic_leader, dept_leader, course_owner, course_creator |
| `create` | `courseversion` | director, ceo, education_leader, academic_leader, dept_leader, course_creator |
| `promote` (review) | `courseversion` | course_creator, dept_leader, academic_leader, education_leader, director, ceo |
| `promote` (approved) | `courseversion` | dept_leader, academic_leader, education_leader, director, ceo (course_creator TIDAK boleh approve sendiri) |

`courseversion` resource baru — tambah ke matrix di Plan Task 0.

---

## §3 UI Layout

### Versions Tab — 3-zone layout

```
┌─ Versions Tab ─────────────────────────────────────────────────────────┐
│ ┌─ Header ─────────────────────────────────────────────────────────┐  │
│ │ Course Type: [Reguler ▼]              [+ Create New Version]     │  │
│ └──────────────────────────────────────────────────────────────────┘  │
│ ┌─ Timeline (1/3) ──────┐  ┌─ Detail (2/3) ──────────────────────┐   │
│ │ v2.1.0  [approved] ←  │  │ v2.1.0                              │   │
│ │ Apr 28, 2026          │  │ Status: approved                    │   │
│ │ minor                 │  │ Change Type: minor                  │   │
│ │ ─────────────────     │  │ Approved by: Jane Doe               │   │
│ │ v2.0.1  [archived]    │  │ Approved at: Apr 28, 2026 14:30     │   │
│ │ Apr 14, 2026          │  │ ─────────────────                   │   │
│ │ patch                 │  │ Changelog:                          │   │
│ │ ─────────────────     │  │ - Added module on advanced topics   │   │
│ │ v1.0.0  [archived]    │  │ - Refined assessment rubric         │   │
│ │ Mar 1, 2026           │  │ ─────────────────                   │   │
│ │ major                 │  │ [No actions — terminal status]      │   │
│ └───────────────────────┘  └─────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

### Timeline Item States
- **draft** → gray badge, Promote-to-Review button visible
- **review** → amber badge, Promote-to-Approved button visible (role-gated)
- **approved** → green badge, no actions, "currently active" indicator
- **archived** → muted/opacity-60, no actions

### Empty States
- No CourseTypes → "Create a CourseType first" + link ke Variants tab
- No versions for selected type → "No versions yet. Create the first version." + CTA `+ Create New Version`
- No selection → "Select a version to see details"

### Create Form
- Trigger: `+ Create New Version` button → modal/drawer
- Fields:
  - `change_type` (Select: major/minor/patch) — required
  - `version_number` — auto-suggested dari latest existing version + changeType (read-only by default, toggle "edit manually" untuk override)
  - `changelog` (TextArea) — required, min 10 char
- Submit → POST → toast → list refresh, select new version

### Promote Action
- Confirm dialog:
  - draft→review: "Submit for review? Reviewer will be notified."
  - review→approved: "Approve this version? This will archive any currently approved version."
- approved promote: `approved_by` UUID auto-filled dari current user

### Validation Visual
- `version_number` regex `^\d+\.\d+\.\d+$` (zod refine)
- `changelog` min 10 char
- `change_type` enum

---

## §4 Schema, Types, API

### Type — `frontend/src/types/courseversion.ts`
```ts
export type CourseVersionStatus = 'draft' | 'review' | 'approved' | 'archived'
export type ChangeType = 'major' | 'minor' | 'patch'

export interface CourseVersion {
  id: string
  course_type_id: string
  version_number: string
  status: CourseVersionStatus
  change_type: ChangeType
  changelog: string
  created_by?: string | null
  approved_by?: string | null
  created_at: string
  updated_at: string
  approved_at?: string | null
  archived_at?: string | null
}
```

### Schema — `frontend/src/schemas/courseversion.ts`
```ts
import { z } from 'zod'

export const CHANGE_TYPES = ['major', 'minor', 'patch'] as const
export const VERSION_STATUSES = ['draft', 'review', 'approved', 'archived'] as const
const VERSION_REGEX = /^\d+\.\d+\.\d+$/

export const createCourseVersionSchema = z.object({
  version_number: z.string().regex(VERSION_REGEX, 'Format: MAJOR.MINOR.PATCH (mis. 1.2.3)'),
  change_type: z.enum(CHANGE_TYPES),
  changelog: z.string().min(10, 'Changelog minimal 10 karakter').max(5000),
})

export const promoteCourseVersionSchema = z.object({
  target_status: z.enum(['review', 'approved']),
  approved_by: z.string().uuid().optional(),
}).refine(
  (d) => d.target_status !== 'approved' || !!d.approved_by,
  { message: 'approved_by wajib saat promote ke approved', path: ['approved_by'] }
)

export type CreateCourseVersionInput = z.infer<typeof createCourseVersionSchema>
export type PromoteCourseVersionInput = z.infer<typeof promoteCourseVersionSchema>

// Helper: bump version
export function nextVersion(current: string, changeType: ChangeType): string {
  const [maj, min, pat] = current.split('.').map(Number)
  if (changeType === 'major') return `${maj + 1}.0.0`
  if (changeType === 'minor') return `${maj}.${min + 1}.0`
  return `${maj}.${min}.${pat + 1}`
}
```

### API Endpoints (verified handler)
| Method | Path |
|---|---|
| GET | `/api/v1/curriculum/types/{typeID}/versions` |
| POST | `/api/v1/curriculum/types/{typeID}/versions` |
| GET | `/api/v1/curriculum/versions/{versionID}` |
| POST | `/api/v1/curriculum/versions/{versionID}/promote` |

### React-Query Hooks
```
useCourseVersions(typeId)                  // ['courseversions', 'list', typeId]
useCourseVersion(versionId)                // ['courseversions', versionId]
useCreateCourseVersion(typeId)             // invalidates list
usePromoteCourseVersion(typeId)            // invalidates list + [versionId]
```

---

## §5 Migration

### CourseDetail.tsx
1. Tambah render block:
   ```tsx
   {tab === 'versions' && <VersionsTab courseId={id} />}
   ```
2. Un-disable Versions tab (currently no-op).
3. Tab `Cert`/`Settings` tetap no-op sampai iter terkait.

### Permission Matrix
Tambah `courseversion` ke `lib/auth/permissions.ts`:
- list/read: course_owner + course_creator + 4 leader roles + director/ceo
- create: course_creator + 3 leader roles + director/ceo
- promote: split logic — UI menampilkan tombol Promote-to-Approved hanya jika role bukan course_creator

---

## §6 Testing & Done Criteria

### Unit Tests (vitest)
`schemas/__tests__/courseversion.test.ts`:
1. accepts valid version_number (`1.0.0`, `12.34.567`)
2. rejects invalid format (`1.0`, `v1.0.0`, `1.0.0-beta`)
3. rejects changelog < 10 char
4. accepts all 3 CHANGE_TYPES
5. promote schema rejects `approved` without `approved_by`
6. `nextVersion('1.2.3', 'major') === '2.0.0'`, `minor === '1.3.0'`, `patch === '1.2.4'`

### Manual Smoke (10 skenario)
1. Login `dept_leader` → `/internal/courses/:id` → Versions tab → "Create CourseType first" empty state (kalau belum ada type)
2. Setelah ada CourseType → dropdown muncul, list versi kosong → empty state + CTA
3. `+ Create New Version` → modal, default change_type=patch, version_number auto-suggested
4. Submit valid (change_type=minor, changelog "Initial release") → toast, list update, status `draft`
5. Click version → detail panel render lengkap
6. Promote draft→review → confirm → toast → status `review`
7. Promote review→approved → confirm → status `approved`, approved_at terisi, approved_by terisi
8. Buat versi kedua, promote ke approved → versi pertama otomatis menjadi `archived` (server-side) → list refresh menampilkan
9. Login `course_creator` → bisa create + promote-to-review, tapi TIDAK bisa promote-to-approved (button disabled/hidden)
10. Login `facilitator` → tab Versions read-only, no Create button, no Promote

### Done Criteria
- [ ] Versions tab functional
- [ ] List + Detail + Create + Promote berjalan
- [ ] Auto-suggest version_number works
- [ ] Schema test pass (6 cases)
- [ ] Permission gates berfungsi (course_creator vs dept_leader vs facilitator)
- [ ] typecheck + vitest hijau
- [ ] 10 manual smoke skenario pass

---

## §7 Risks

| Risk | Mitigasi |
|---|---|
| `courseversion` resource belum ada di matrix | Plan Task 0: tambah |
| `approved_by` UUID source — current user? | Pakai `useAuthStore().user.id`; verify field name di Plan Task 0 |
| Backend response shape `data: [...]` vs `[...]` | Defensive parse, sama dgn pola CourseType |
| Auto-suggest version vs manual override conflict | Toggle "edit manually" — default read-only, click toggle untuk free input |
| Archive otomatis saat approve — ada race? | Backend handle in-transaction; FE invalidate list setelah promote sukses |
| Backend promote TIDAK terima `target_status=draft` (rollback) | Tidak scope — hanya forward transition |
| Tidak ada Edit endpoint | Document sebagai out-of-scope; user delete & recreate kalau salah |

---

## §8 Next Steps

1. User review spec
2. Approved → invoke `superpowers:writing-plans` skill untuk plan implementasi Iter 1C
3. Setelah Iter 1C merged → Iter 1D (CourseModule — list/CRUD modules dlm version, reorder DnD)
