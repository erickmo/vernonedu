# Curriculum Iter 1A — MasterCourse CRUD

**Date:** 2026-05-02
**Type:** Implementation spec (Fase 1 Curriculum, Iterasi 1A)
**Roadmap:** `docs/superpowers/specs/2026-05-02-frontend-crud-parity-roadmap.md` Bucket 1
**Status:** Draft → User Review

---

## §1 Purpose & Scope

### Tujuan
Surface proper MasterCourse CRUD via 1 page hybrid `Courses`. Replace existing flat `Course` abstraction. Tab Overview saja untuk iter ini — Variants/Versions/Cert/Configs di iter B–E.

### In-scope
- List page `/internal/courses` — list MasterCourse (replace existing)
- Create page `/internal/courses/new` — form MasterCourse
- Detail page `/internal/courses/:id` — Overview tab aktif, tab lain disabled
- Edit page `/internal/courses/:id/edit`
- Action: archive (status → archived)
- Permission gate via `RoleGate`
- Hapus `CreateCourseModal` lama

### Out-of-scope (iter berikutnya)
- Variants (CourseType) — Iter 1B
- Versions (CourseVersion + CourseModule) — Iter 1C
- Certificate Template tab — Iter 1D
- Configs (Internship + CharacterTest) — Iter 1E
- Migrasi data DB

### Field MasterCourse (per backend `create_mastercourse`)
| Field | Type | Required | Note |
|---|---|---|---|
| `course_code` | string | ✓ | unique, max 20 |
| `course_name` | string | ✓ | max 200 |
| `field` | enum | ✓ | Tech / Business / Design / Education / Other |
| `core_competencies` | string[] | — | multi-input chips |
| `description` | string | — | textarea, max 2000 |
| `supporting_app_url` | URL | — | optional |
| `status` | enum | — | active / archived; read-only di create |

### Open Questions Resolved
- `department_id` — bukan field MasterCourse di backend. **Drop.** Relasi department dikelola di tempat lain.
- `duration_days`, `format` — pindah ke CourseType di iter 1B. **Drop dari MasterCourse.**

---

## §2 Architecture & Components

### File Map

| File | Action | Tujuan |
|---|---|---|
| `frontend/src/types/mastercourse.ts` | Create | Type `MasterCourse`, `MasterCourseFilters` |
| `frontend/src/schemas/mastercourse.ts` | Create | Zod schema create/update + `FIELDS` enum |
| `frontend/src/lib/api/curriculum.ts` | Create | React-query hooks |
| `frontend/src/portals/internal/pages/Courses.tsx` | Replace | List page baru pola Partner |
| `frontend/src/portals/internal/pages/CourseCreatePage.tsx` | Create | Form create dgn `StandardPageLayout` |
| `frontend/src/portals/internal/pages/CourseEditPage.tsx` | Create | Form edit prefilled |
| `frontend/src/portals/internal/pages/detail/CourseDetail.tsx` | Replace | Detail dgn tabs (Overview aktif) |
| `frontend/src/portals/internal/components/CreateCourseModal.tsx` | Delete | Replaced by CourseCreatePage |
| `frontend/src/lib/api/catalog.ts` | Modify | Mark `Course`, `useCourses`, `useCourse` deprecated (tetap untuk student) |
| `frontend/src/App.tsx` | Modify | Tambah route `/courses/new`, `/courses/:id/edit` (sebelum `/:id`) |

### Komponen Shared Baru

| Komponen | Path | Tujuan |
|---|---|---|
| `TabNav` | `frontend/src/components/shared/TabNav.tsx` | Reusable tab nav untuk CourseDetail (dipakai juga domain lain dgn tab) |
| `MultiInput` | `frontend/src/components/shared/MultiInput.tsx` | Input chips untuk `core_competencies` (string[]) |

### Data Flow
```
List   → useMasterCourses(filters) → GET /api/v1/master-courses
Detail → useMasterCourse(id)       → GET /api/v1/master-courses/:id
Create → useCreateMasterCourse()   → POST /api/v1/master-courses
                                    → invalidate ['mastercourses', 'list']
Edit   → useUpdateMasterCourse()   → PUT  /api/v1/master-courses/:id
                                    → invalidate ['mastercourses', 'list'] + ['mastercourses', id]
Archive→ useArchiveMasterCourse()  → POST /api/v1/master-courses/:id/archive
                                    → invalidate same
```

### Permission
| Action | Resource | Roles via matrix |
|---|---|---|
| `list`, `read` | `mastercourse` | director, ceo, education_leader, academic_leader, dept_leader, course_owner (read), course_creator |
| `create` | `mastercourse` | director, ceo, education_leader, academic_leader, dept_leader, course_creator |
| `update` | `mastercourse` | same as create |
| `delete` (archive) | `mastercourse` | director, ceo, education_leader, dept_leader |

Gate via `<RoleGate action="..." resource="mastercourse">`.

---

## §3 UI Layouts

### List Page (`/internal/courses`)
```
┌─ PageHeader ──────────────────────────────────────────┐
│ Courses                          [+ Add Course]       │ ← gated: create/mastercourse
│ Manage curriculum master courses                      │
└───────────────────────────────────────────────────────┘
┌─ Filters ─────────────────────────────────────────────┐
│ [Search code/name] [Field ▼] [Status: All|Active|Arc] │
└───────────────────────────────────────────────────────┘
┌─ DataTable ───────────────────────────────────────────┐
│ Code     Name              Field      Status          │
│ MC-001   Web Dev           Tech       Active          │
│ MC-002   Data Sci          Tech       Active          │
└───────────────────────────────────────────────────────┘
[‹ 1 / 5 ›]
```
Row click → `/internal/courses/:id`.

### Create Page (`/internal/courses/new`)
`StandardPageLayout` shell. Body:
```
Course Code*       [_____________]
Course Name*       [_____________]
Field*             [Select ▼     ]
Core Competencies  [chip] [chip] [+]   ← MultiInput
Description        [textarea       ]
Supporting App URL [_____________]
                                       [Cancel] [Save]
```

### Edit Page (`/internal/courses/:id/edit`)
Sama dgn create, prefilled. Plus toggle Status (Active ⇆ Archived) — gated `delete/mastercourse`.

### Detail Page (`/internal/courses/:id`)
```
┌─ Header ──────────────────────────────────────────────┐
│ ← Back                                  [Edit] [⋯]   │
│ MC-001 · Web Development                              │
│ Field: Tech · Status: Active                          │
└───────────────────────────────────────────────────────┘
┌─ Tabs ────────────────────────────────────────────────┐
│ [Overview] [Variants] [Versions] [Cert] [Settings]   │
│  ════════   disabled   disabled   disabled  disabled  │
└───────────────────────────────────────────────────────┘
┌─ Overview Tab ────────────────────────────────────────┐
│ Description: ...                                      │
│ Core Competencies: [chip] [chip] [chip]               │
│ Supporting App: <link>                                │
│ Created: 2026-04-12 · Updated: 2026-04-30             │
└───────────────────────────────────────────────────────┘
```
Tab disabled tooltip: "Coming in Iter 1B/C/D".

### States
- **Empty:** "No courses yet" + CTA "Add your first course" (gated)
- **Loading:** skeleton rows (existing `DataTable`)
- **Error:** existing `ErrorBoundary` + `sonner` toast

---

## §4 Schema, Types, API Contract

### Type — `frontend/src/types/mastercourse.ts`
```ts
export interface MasterCourse {
  id: string
  course_code: string
  course_name: string
  field: string
  core_competencies: string[]
  description: string
  supporting_app_url?: string
  status: 'active' | 'archived'
  created_at: string
  updated_at: string
}

export interface MasterCourseFilters {
  search?: string
  field?: string
  status?: 'active' | 'archived'
  page?: number
  limit?: number
}
```

### Schema — `frontend/src/schemas/mastercourse.ts`
```ts
import { z } from 'zod'

export const FIELDS = ['Tech', 'Business', 'Design', 'Education', 'Other'] as const

export const createMasterCourseSchema = z.object({
  course_code: z.string().min(1, 'Code wajib').max(20),
  course_name: z.string().min(1, 'Name wajib').max(200),
  field: z.enum(FIELDS),
  core_competencies: z.array(z.string().min(1)).default([]),
  description: z.string().max(2000).default(''),
  supporting_app_url: z.string().url().optional().or(z.literal('')),
})

export const updateMasterCourseSchema = createMasterCourseSchema.partial()

export type CreateMasterCourseInput = z.infer<typeof createMasterCourseSchema>
export type UpdateMasterCourseInput = z.infer<typeof updateMasterCourseSchema>
```

### API Contract (verify saat plan)
| Method | Path | Body / Query | Response |
|---|---|---|---|
| GET | `/api/v1/master-courses` | `?search=&field=&status=&page=&limit=` | `PaginatedResponse<MasterCourse>` |
| GET | `/api/v1/master-courses/:id` | — | `MasterCourse` |
| POST | `/api/v1/master-courses` | `CreateMasterCourseInput` | `MasterCourse` |
| PUT | `/api/v1/master-courses/:id` | `UpdateMasterCourseInput` | `MasterCourse` |
| POST | `/api/v1/master-courses/:id/archive` | — | `{ success: true }` |

### React-Query Hooks — `frontend/src/lib/api/curriculum.ts`
```
useMasterCourses(filters)    // ['mastercourses', 'list', filters]
useMasterCourse(id)          // ['mastercourses', id]
useCreateMasterCourse()      // invalidates ['mastercourses', 'list']
useUpdateMasterCourse()      // invalidates list + [id]
useArchiveMasterCourse()     // invalidates same
```

### Open Question
Backend route exact path (`/master-courses` vs `/mastercourses` vs `/courses`?). Verify saat plan dgn `grep -n "master.course\|mastercourse" api/cmd/api/main.go`.

---

## §5 Migration & Backward Compat

### Konsumen Existing `Course`

Identifikasi saat plan via:
```bash
grep -rn "useCourses\|useCourse\b\|type Course\b" frontend/src --include="*.tsx" --include="*.ts"
```

### Strategi
- **Internal portal:** ganti penuh ke `MasterCourse` hooks
- **Student portal (`portals/student/pages/CourseCatalog.tsx`, `CourseDetail.tsx`):** student butuh field gabungan (price, duration, format) yg di-derive dari MasterCourse + default CourseType. **Decision:** tetap pakai `useCourses` flat di student. Implementasi composite view di iter 1B. Iter 1A: `Course` type alias dipertahankan tapi di-mark `@deprecated`.

### Action di Iter 1A
- `lib/api/catalog.ts`: tambah JSDoc `@deprecated — pakai curriculum.useMasterCourse(s) untuk admin views`. Tidak hapus.
- `lib/api/curriculum.ts`: baru, mandiri.
- `Courses.tsx` (internal): full ganti ke MasterCourse.
- Student catalog: tidak diubah.

### Risk
Page lain mungkin pakai `Course.duration_days` / `Course.format`. Verify lewat grep, jangan bypass build error.

### No DB Migration
Backend table sudah ada.

---

## §6 Testing & Done Criteria

### Unit Tests (vitest)
- `schemas/mastercourse.test.ts`:
  - createSchema validates required fields
  - rejects empty code/name
  - accepts valid URL + empty string
  - rejects malformed URL
- `lib/auth/permissions.test.ts` (existing): verify mastercourse matrix sudah cover dept_leader create+update

### Component Tests (defer ke iter berikut bila berat)
- `RoleGate` integration: Add button hidden untuk facilitator
- `MultiInput`: add/remove chip behavior

### Manual Smoke (wajib lulus sebelum merge)
1. Login as `dept_leader` → `/internal/courses` → list muncul
2. Click "Add Course" → form → submit minimal valid → redirect ke detail
3. Edit course → ubah name → save → list ter-update
4. Archive → status badge "Archived"
5. Login as `facilitator` → tombol Add hidden, tabel read-only
6. Login as `student` → akses `/internal/courses` → 403 / redirect

### Done Criteria
- [ ] List / Detail / Create / Edit page jalan
- [ ] MasterCourse field lengkap (code, name, field, core_competencies, description, supporting_app_url, status)
- [ ] Archive action berfungsi
- [ ] Permission gate: tombol Add hidden untuk role tanpa izin
- [ ] CreateCourseModal lama dihapus
- [ ] Student catalog tidak regressi
- [ ] `npm run typecheck` + `npm test` hijau
- [ ] 6 manual smoke skenario pass

---

## §7 Risks

| Risk | Mitigasi |
|---|---|
| Backend route path ambiguous | Verify saat plan: `grep -n "master.course\|mastercourse" api/cmd/api/main.go` |
| `field` enum drift FE↔BE | FE pakai dropdown enum, backend accept string bebas. Sync via settings nanti bila perlu. |
| Student catalog regressi | Hold flat `Course` di `catalog.ts`, tidak ubah student pages |
| `MultiInput` component baru bug | Test ringan + cek apakah ada existing pattern di `frontend/src/components/` sebelum buat baru |
| Tab disabled UX confusing | Tooltip "Coming in Iter 1B/C/D" pada tab disabled |

---

## §8 Next Steps

1. User review spec
2. Approved → invoke `superpowers:writing-plans` skill untuk plan implementasi Iter 1A
3. Setelah Iter 1A merged → brainstorm Iter 1B (Variants / CourseType)
