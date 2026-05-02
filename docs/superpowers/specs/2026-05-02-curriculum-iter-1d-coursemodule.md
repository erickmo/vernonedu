# Curriculum Iter 1D — CourseModule (Inline in Version Detail)

**Date:** 2026-05-02
**Type:** Implementation spec (Fase 1 Curriculum, Iterasi 1D)
**Roadmap:** `docs/superpowers/specs/2026-05-02-frontend-crud-parity-roadmap.md` Bucket 1
**Predecessor:** `docs/superpowers/specs/2026-05-02-curriculum-iter-1c-courseversion.md`
**Status:** Draft → User Review

---

## §1 Purpose & Scope

### Tujuan
CRUD CourseModule inline dalam `VersionDetailPanel`. Drag-drop reorder. Lock edit saat version `approved`/`archived`.

### In-scope
- Render modules section di bawah changelog dalam `VersionDetailPanel`
- List modules ordered by `sequence`
- Create module (drawer/modal) dgn semua field
- Edit module (same drawer)
- Delete module (confirm dialog)
- Drag-drop reorder via `@dnd-kit/core`/`@dnd-kit/sortable` (1 PUT per affected module untuk update sequence; optimistic local reorder)
- Lock UI saat `version.status ∈ {approved, archived}` — list view-only, no Add/Edit/Delete/Reorder
- Permission via `RoleGate` (`coursemodule` resource sudah di matrix)

### Out-of-scope
- Reference modules UI (`is_reference`, `ref_module_id`) — defer iter 1E
- Bulk reorder atomic (no backend endpoint — N PUT serial)
- Duplicate module across versions
- Module-level approval workflow
- Topics/practical_activities/etc rich text — pakai MultiInput chip-style (string[])

### Default policy decisions
- **Lock approved/archived:** tidak boleh ubah modul setelah versi ter-approve. Bikin versi baru utk perubahan kurikulum.
- **Optimistic reorder:** UI swap langsung saat drop, async PUTs di background. Rollback + toast error kalau gagal.
- **`module_code` uniqueness:** server enforce (FE tidak validate; tampilkan error message dari backend kalau bentrok).

---

## §2 Architecture & Components

### File Map

| File | Action | Tujuan |
|---|---|---|
| `frontend/src/types/coursemodule.ts` | Create | `CourseModule` |
| `frontend/src/schemas/coursemodule.ts` | Create | Zod schema (create + update variants) |
| `frontend/src/schemas/__tests__/coursemodule.test.ts` | Create | 5-6 unit tests |
| `frontend/src/lib/api/curriculum.ts` | Modify | Tambah 5 hook: list/get/create/update/delete |
| `frontend/src/portals/internal/components/curriculum/ModuleList.tsx` | Create | Sortable table + DnD |
| `frontend/src/portals/internal/components/curriculum/ModuleRow.tsx` | Create | Sortable row |
| `frontend/src/portals/internal/components/curriculum/ModuleForm.tsx` | Create | Drawer create/edit form |
| `frontend/src/portals/internal/components/curriculum/ModulesSection.tsx` | Create | Container — header + Add button + ModuleList + ModuleForm slot |
| `frontend/src/portals/internal/components/curriculum/VersionDetailPanel.tsx` | Modify | Render `<ModulesSection version={v}/>` di bawah changelog |
| `frontend/package.json` | Modify | Add `@dnd-kit/core`, `@dnd-kit/sortable`, `@dnd-kit/utilities` |

### Komponen Shared
Reuse: `MultiInput`, `FormField`, `Button`, `Input`, `Select`, `Textarea`, `RoleGate`, `LoadingSpinner`. No new shared component.

### Folder
Tetap di `portals/internal/components/curriculum/`.

### Data Flow
```
VersionDetailPanel(versionId, typeId)
  └── ModulesSection(version)
        ├── header: "Modules ({count})" + [+ Add] (jika canCreate && !locked)
        ├── ModuleList(versionId, locked)
        │     ├── useCourseModules(versionId) → list (sorted by sequence)
        │     └── DndContext → SortableContext → ModuleRow[]
        │           ├── click row → setEditingId
        │           ├── delete button → useDeleteCourseModule
        │           └── drag handle → onDragEnd → reorder PUTs
        └── ModuleForm (drawer, mode='create'|'edit', open state)
              ├── useCreateCourseModule(versionId)
              └── useUpdateCourseModule(moduleId, versionId)
```

### Permission
| Action | Resource | Roles | Catatan |
|---|---|---|---|
| `list`, `read` | `coursemodule` | semua role yg punya entries (sudah di matrix) | — |
| `create`, `update`, `delete` | `coursemodule` | dept_leader, course_creator, leader roles, director, ceo | DI-LOCK kalau version approved/archived |

Tidak perlu update matrix — sudah lengkap.

---

## §3 UI Layout

### ModulesSection (di dalam VersionDetailPanel)

```
─────────────────────────────────────────────────────────────────
Changelog:
[changelog text in pre block]
─────────────────────────────────────────────────────────────────
Modules (5)                          [+ Add Module]   ← hidden if locked
─────────────────────────────────────────────────────────────────
┌─ ModuleList table ─────────────────────────────────────────────┐
│  ⋮⋮  #  Code        Title              Duration  Tools  Actions │
│ ───────────────────────────────────────────────────────────────│
│  ⋮⋮  1  CODE-001    Pemrograman Dasar    8 jam   2     ✎  🗑  │
│  ⋮⋮  2  CODE-002    Logika Algoritma     6 jam   1     ✎  🗑  │
│  ⋮⋮  3  CODE-003    Struktur Data       10 jam   3     ✎  🗑  │
└────────────────────────────────────────────────────────────────┘
```

### Lock state (version approved/archived)
```
Modules (5)        [🔒 Version approved — modules read-only]
─────────────────────────────────────────────────────────────────
(table tanpa drag handle, tanpa Edit/Delete kolom)
```

### Empty state
"No modules yet. Click + Add Module to start."

### Drag-drop visual
- Drag handle `⋮⋮` di kiri row, cursor=grab
- Saat drag: row opacity 50%, ghost overlay menempel cursor
- Drop area highlight pakai `useSortable` outline
- After drop: optimistic reorder local; PUT serial; jika error toast + rollback

### Module Form (drawer/sheet kanan)

```
┌─ New Module / Edit Module ────────────────────┐
│ Module Code*       [_____________]            │
│ Module Title*      [_____________]            │
│ Sequence*          [__]   Duration (jam) [__]│
│ Content Depth      [_____________]            │
│ Assessment Method  [_____________]            │
│ Topics             [chip] [chip] [+]          │
│ Practical Activities [chip] [chip] [+]        │
│ Tools Required     [chip] [chip] [+]          │
│ Requirements       [chip] [chip] [+]          │
│                                                │
│              [Cancel] [Save]                   │
└────────────────────────────────────────────────┘
```

### Validation visual
- module_code: required, min 1 char
- module_title: required, min 1 char
- sequence: required, integer ≥ 1
- duration_hours: optional, ≥ 0
- arrays default `[]`
- Server uniqueness error → inline error pada `module_code`

---

## §4 Schema, Types, API

### Type — `frontend/src/types/coursemodule.ts`
```ts
export interface CourseModule {
  id: string
  course_version_id: string
  module_code: string
  module_title: string
  duration_hours: number
  sequence: number
  content_depth: string
  topics: string[]
  practical_activities: string[]
  assessment_method: string
  tools_required: string[]
  requirements: string[]
  is_reference: boolean
  ref_module_id?: string | null
  created_at: string | number
  updated_at: string | number
}
```

### Schema — `frontend/src/schemas/coursemodule.ts`
```ts
import { z } from 'zod'

export const createCourseModuleSchema = z.object({
  module_code: z.string().min(1, 'Module code wajib').max(50),
  module_title: z.string().min(1, 'Module title wajib').max(200),
  duration_hours: z.number().nonnegative().default(0),
  sequence: z.number().int().positive(),
  content_depth: z.string().max(2000).default(''),
  topics: z.array(z.string().min(1)).default([]),
  practical_activities: z.array(z.string().min(1)).default([]),
  assessment_method: z.string().max(500).default(''),
  tools_required: z.array(z.string().min(1)).default([]),
  requirements: z.array(z.string().min(1)).default([]),
  is_reference: z.boolean().default(false),
})

// Update tidak menerima module_code (PUT handler tidak terima — verify backend)
export const updateCourseModuleSchema = createCourseModuleSchema.omit({
  module_code: true,
  is_reference: true,
})

export type CreateCourseModuleInput = z.infer<typeof createCourseModuleSchema>
export type UpdateCourseModuleInput = z.infer<typeof updateCourseModuleSchema>
```

### API Endpoints (verified handler)
| Method | Path |
|---|---|
| GET | `/api/v1/curriculum/versions/{versionID}/modules` |
| POST | `/api/v1/curriculum/versions/{versionID}/modules` |
| GET | `/api/v1/curriculum/modules/{moduleID}` |
| PUT | `/api/v1/curriculum/modules/{moduleID}` |
| DELETE | `/api/v1/curriculum/modules/{moduleID}` |

### React-Query Hooks
```
useCourseModules(versionId)               // ['coursemodules', 'list', versionId]
useCourseModule(moduleId)                 // ['coursemodules', moduleId]
useCreateCourseModule(versionId)          // invalidates list
useUpdateCourseModule(moduleId, versionId)// invalidates list + [moduleId]
useDeleteCourseModule(versionId)          // invalidates list
```

### Reorder helper (no dedicated hook — uses useUpdateCourseModule for each)
```ts
async function reorderModules(
  versionId: string,
  modules: CourseModule[],   // already locally reordered
  updateMutation: ReturnType<typeof useUpdateCourseModule>,
) {
  const updates = modules.map((m, idx) => ({
    moduleId: m.id,
    input: { ...moduleToInput(m), sequence: idx + 1 },
  }))
  // serial PUTs (or Promise.all if backend supports concurrent)
  for (const u of updates) {
    await updateMutation.mutateAsync({ ... })
  }
}
```

> **Note:** simpler — only PUT modules whose sequence changed. Compute diff first.

---

## §5 Lock Logic

```tsx
const locked = version.status === 'approved' || version.status === 'archived'

// In ModulesSection:
<RoleGate action="create" resource="coursemodule">
  {!locked && <Button onClick={openCreate}>+ Add Module</Button>}
</RoleGate>
{locked && <Badge>Version {version.status} — read-only</Badge>}

// Inside ModuleList: pass locked prop → hide drag handle, hide actions column
```

---

## §6 Testing & Done Criteria

### Unit Tests (vitest)
`schemas/__tests__/coursemodule.test.ts` (6 cases):
1. accepts valid input (all fields)
2. rejects empty module_code
3. rejects empty module_title
4. rejects sequence ≤ 0
5. rejects negative duration_hours
6. accepts empty arrays for topics/tools/requirements

### Manual Smoke (12 skenario)
1. Login dept_leader → `/internal/courses/:id` → Versions tab → pilih version `draft` → modules section muncul, kosong, empty state + CTA
2. Click `+ Add Module` → drawer muncul, default sequence=1
3. Submit valid input → toast → row muncul di table
4. Add 4 modul lagi → table render dgn sequence 1-5
5. Drag modul ke-3 ke posisi 1 → optimistic UI swap → toast saat semua PUT selesai
6. Refresh page → urutan persist
7. Click ✎ → drawer prefilled → ubah module_title → save → row update
8. Click 🗑 → confirm → row hilang → list refresh
9. Switch ke version `approved` → `+ Add` hidden, no drag handle, no edit/delete buttons; "read-only" badge
10. Login course_creator → bisa Add/Edit/Delete + Reorder pada version draft milik sendiri
11. Login facilitator → modules visible (read-only), no Add/Edit/Delete
12. Submit module_code yg sudah dipakai → error message dari backend muncul inline

### Done Criteria
- [ ] @dnd-kit deps installed
- [ ] Type + zod schema + 6 tests
- [ ] 5 react-query hooks
- [ ] 4 komponen baru (ModuleRow, ModuleList, ModuleForm, ModulesSection)
- [ ] VersionDetailPanel renders ModulesSection
- [ ] Lock policy berlaku (approved/archived → read-only)
- [ ] DnD reorder berjalan + persist
- [ ] typecheck + vitest hijau
- [ ] 12 smoke pass

---

## §7 Risks

| Risk | Mitigasi |
|---|---|
| `@dnd-kit` adds bundle size | Acceptable — battle-tested DnD lib |
| Reorder N PUTs slow / partial fail | Diff-based (only changed sequence). Toast + rollback on error. Future: backend bulk endpoint |
| Backend `Update` tidak terima `module_code` | Plan Task 0: verify; jika perlu code, sertakan field dgn nilai tetap |
| Backend response shape | Mirror coursetype/version (defensive `data.data`) |
| Lock bypass via API call | Backend harus enforce — out of FE scope |
| Drag handle conflicts dgn click row (open edit) | Pisahkan area: handle kiri only, click row body open edit |
| Concurrent reorder + create | Disable Add button selama reorder pending |
| Topics/activities arrays besar | MultiInput sudah tested di iter 1A/1B |

---

## §8 Next Steps

1. User review spec
2. Approved → invoke `superpowers:writing-plans` skill untuk plan implementasi Iter 1D
3. Setelah Iter 1D merged → Iter 1E (CertificateTemplate + InternshipConfig + CharacterTestConfig + reference modules)
