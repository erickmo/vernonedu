# Curriculum Iter 1B — CourseType (Variants Tab)

**Date:** 2026-05-02
**Type:** Implementation spec (Fase 1 Curriculum, Iterasi 1B)
**Roadmap:** `docs/superpowers/specs/2026-05-02-frontend-crud-parity-roadmap.md` Bucket 1
**Predecessor:** `docs/superpowers/specs/2026-05-02-curriculum-iter-1a-mastercourse.md`
**Status:** Draft → User Review

---

## §1 Purpose & Scope

### Tujuan
Aktifkan Variants tab di CourseDetail. CRUD CourseType inline dgn master-detail layout.

### In-scope
- Variants tab aktif di `/internal/courses/:id` (replace placeholder)
- List CourseType per MasterCourse (cards)
- Create CourseType
- Edit CourseType
- Toggle active/inactive
- Field: TypeName, PriceType, PriceCurrency, TargetAudience, CertificationType, ExtraDocs, NormalPrice, MinPrice, MinParticipants, MaxParticipants
- Permission gate via `RoleGate` + `canAccess`

### Out-of-scope
- `ComponentFailureConfig` (Program Karir specific) → Iter 1E
- Delete (backend tidak expose, hanya toggle)
- Pricing override workflow
- Multi-currency (hard-code IDR)
- Number formatting cantik (defer)

### Standard Type Names (FE enum)
- Reguler
- Privat
- Program Karir
- Inhouse
- Kolaborasi Sekolah/Univ

Backend menerima string bebas; FE pakai dropdown enum sebagai default + opsi custom (jika dibutuhkan, tambah option "Other" + free input — defer untuk sekarang, enum saja).

---

## §2 Architecture & Components

### File Map

| File | Action | Tujuan |
|---|---|---|
| `frontend/src/types/coursetype.ts` | Create | `CourseType`, `CourseTypeStatus` |
| `frontend/src/schemas/coursetype.ts` | Create | Zod schema + `TYPE_NAMES`, `PRICE_TYPES`, `CURRENCIES` |
| `frontend/src/schemas/__tests__/coursetype.test.ts` | Create | 6 unit tests |
| `frontend/src/lib/api/curriculum.ts` | Modify | Tambah 5 hook: list/get/create/update/toggle |
| `frontend/src/portals/internal/components/curriculum/VariantsTab.tsx` | Create | Container master-detail |
| `frontend/src/portals/internal/components/curriculum/VariantCard.tsx` | Create | Card list item dgn toggle status visual |
| `frontend/src/portals/internal/components/curriculum/VariantForm.tsx` | Create | Form create/edit (right panel) |
| `frontend/src/portals/internal/pages/detail/CourseDetail.tsx` | Modify | Render `<VariantsTab/>` saat `tab === 'variants'`, un-disable tab |
| `frontend/src/lib/auth/permissions.ts` | Verify/Modify | Pastikan `coursetype` matrix entries lengkap |

### Komponen Shared
Reuse: `MultiInput`, `FormField`, `StatusBadge`, `Button`, `Input`, `Select`, `RoleGate`, `LoadingSpinner`. No new shared component.

### Folder Baru
`frontend/src/portals/internal/components/curriculum/` — group untuk komponen Curriculum bucket. Iter 1C/1D/1E akan tambah komponen lain di folder yg sama.

### Data Flow
```
VariantsTab(courseId)
  ├── useCourseTypes(courseId) → list
  │   └── VariantCard (per item) — click → setSelectedId(id)
  │                              — toggle button → useToggleCourseType
  └── VariantForm(courseId, mode, selectedId?)
        - mode 'create' → useCreateCourseType
        - mode 'edit'   → useUpdateCourseType
```

### Permission
| Action | Resource | Roles via matrix |
|---|---|---|
| `list`, `read` | `coursetype` | director, ceo, education_leader, academic_leader, dept_leader, course_owner (read), course_creator |
| `create`, `update` | `coursetype` | director, ceo, education_leader, academic_leader, dept_leader, course_creator |

`coursetype` resource sudah terdaftar di permission matrix (Iter prerequisite). Verify saat plan apakah role `update` lengkap; tambah jika kurang.

---

## §3 UI Layout

### Variants Tab — Master-Detail Split (1/3 + 2/3)

```
┌─ Variants Tab ────────────────────────────────────────────────────────┐
│ ┌─ Left col (1/3) ──────┐  ┌─ Right col (2/3) ─────────────────────┐ │
│ │ Variants (3)          │  │ Reguler                                │ │
│ │ [+ Add Variant]       │  │ ─────────────────────────────────────  │ │
│ │ ─────────────         │  │ Type Name*    [Reguler ▼]              │ │
│ │ ┌─ VariantCard ─┐    │  │ Price Type    [_______]                │ │
│ │ │ Reguler  [✓] │ ←sel │  │ Currency      [IDR ▼]                  │ │
│ │ │ Rp 5jt-3jt   │    │  │ Target Audience [_______]              │ │
│ │ │ 10-25 ppl    │    │  │ Certification [_______]                │ │
│ │ └──────────────┘    │  │ Extra Docs    [chip] [chip] [+]        │ │
│ │ ┌─ VariantCard ─┐    │  │ Normal Price  [_______]                │ │
│ │ │ Privat   [✓] │    │  │ Min Price     [_______]                │ │
│ │ │ Rp 8jt        │    │  │ Min/Max Part. [__]/[__]                │ │
│ │ │ 1-3 ppl       │    │  │                                         │ │
│ │ └──────────────┘    │  │              [Cancel] [Save]            │ │
│ │ ┌─ VariantCard ─┐    │  │                                         │ │
│ │ │ Karir    [○] │ off │  └────────────────────────────────────────┘ │
│ │ └──────────────┘                                                    │
│ └────────────────────┘                                                │
└──────────────────────────────────────────────────────────────────────┘
```

### Card States
- **Selected** → border-brand
- **Active** → toggle ✓ + green status indicator
- **Inactive** → toggle ○ + opacity-60

### Empty States
- No variants: "No variants yet. Add the first variant to start." + CTA `+ Add Variant`
- No selection (with variants exist): "Select a variant to edit, or click + Add Variant"

### Form Behavior
- Click `+ Add Variant` → form muncul blank, mode=create. Default `type_name=Reguler`, `price_type=one-time`, `price_currency=IDR`.
- Click card → form prefilled, mode=edit
- Save → optimistic toast, list refresh, keep selection
- Cancel → revert form (kalau create: deselect; edit: reset values)

### Toggle
- Inline toggle button di setiap VariantCard
- Confirm dialog kalau active → inactive: "Toggle inactive? Won't appear in batch creation."

### Validation Visual
- Numeric: native `<input type="number" min={0}>` (Rupiah pretty-format defer)
- MinPrice ≤ NormalPrice (zod refine, inline error)
- MinParticipants ≤ MaxParticipants (zod refine, inline error)

---

## §4 Schema, Types, API

### Type — `frontend/src/types/coursetype.ts`
```ts
export type CourseTypeStatus = 'active' | 'inactive'

export interface CourseType {
  id: string
  master_course_id: string
  type_name: string
  price_type: string
  price_currency: string
  target_audience: string
  certification_type: string
  extra_docs: string[]
  normal_price: number
  min_price: number
  min_participants: number
  max_participants: number
  status: CourseTypeStatus
  created_at: string
  updated_at: string
}
```

### Schema — `frontend/src/schemas/coursetype.ts`
```ts
import { z } from 'zod'

export const TYPE_NAMES = [
  'Reguler', 'Privat', 'Program Karir', 'Inhouse', 'Kolaborasi Sekolah/Univ',
] as const

export const PRICE_TYPES = ['one-time', 'monthly', 'per-session'] as const
export const CURRENCIES = ['IDR'] as const

export const createCourseTypeSchema = z.object({
  type_name: z.string().min(1, 'Type name wajib').max(100),
  price_type: z.enum(PRICE_TYPES).default('one-time'),
  price_currency: z.enum(CURRENCIES).default('IDR'),
  target_audience: z.string().max(500).default(''),
  certification_type: z.string().max(200).default(''),
  extra_docs: z.array(z.string().min(1)).default([]),
  normal_price: z.number().int().nonnegative(),
  min_price: z.number().int().nonnegative(),
  min_participants: z.number().int().positive(),
  max_participants: z.number().int().positive(),
}).refine((d) => d.min_price <= d.normal_price, {
  message: 'Min price harus ≤ Normal price',
  path: ['min_price'],
}).refine((d) => d.min_participants <= d.max_participants, {
  message: 'Min participants harus ≤ Max participants',
  path: ['min_participants'],
})

export const updateCourseTypeSchema = createCourseTypeSchema
export type CreateCourseTypeInput = z.infer<typeof createCourseTypeSchema>
export type UpdateCourseTypeInput = CreateCourseTypeInput
```

### API Endpoints (verified from CLAUDE.md + handlers)
| Method | Path |
|---|---|
| GET | `/api/v1/curriculum/courses/{courseID}/types` |
| POST | `/api/v1/curriculum/courses/{courseID}/types` |
| GET | `/api/v1/curriculum/types/{typeID}` |
| PUT | `/api/v1/curriculum/types/{typeID}` |
| POST | `/api/v1/curriculum/types/{typeID}/toggle` |

### React-Query Hooks (extend `lib/api/curriculum.ts`)
```
useCourseTypes(courseId)              // ['coursetypes', 'list', courseId]
useCourseType(typeId)                 // ['coursetypes', typeId]
useCreateCourseType(courseId)         // invalidates ['coursetypes', 'list', courseId]
useUpdateCourseType(typeId, courseId) // invalidates list + [typeId]
useToggleCourseType(courseId)         // invalidates list + [typeId]
```

---

## §5 Migration

### CourseDetail.tsx
1. Hapus early-return guard di `handleTabChange`:
   ```tsx
   function handleTabChange(v: string) {
     setTab(v)  // accept all
   }
   ```
   Atau lebih spesifik: izinkan `'overview'` + `'variants'`, return early untuk sisanya.

2. Tambah render block:
   ```tsx
   {tab === 'variants' && <VariantsTab courseId={id} />}
   ```

3. Tab `Versions`/`Cert`/`Settings` tetap "no-op click" sampai iter terkait.

### Permission Matrix (`lib/auth/permissions.ts`)
Verify pada plan Task 0:
- `coursetype` entry exists untuk education_leader, academic_leader, dept_leader, course_creator
- Jika belum: tambah entries.

---

## §6 Testing & Done Criteria

### Unit Tests (vitest)
`schemas/__tests__/coursetype.test.ts`:
1. accepts minimal valid input (type_name + numeric fields)
2. rejects empty type_name
3. rejects min_price > normal_price (refine error path correct)
4. rejects min_participants > max_participants
5. rejects negative price
6. accepts all 5 standard TYPE_NAMES values

### Manual Smoke (8 skenario, wajib lulus sebelum merge)
1. Login `dept_leader` → `/internal/courses/:id` → click tab Variants → tab aktif, list kosong → empty state
2. Click `+ Add Variant` → form muncul dgn default Reguler/one-time/IDR
3. Submit `type_name=Reguler, normal_price=5000000, min_price=3000000, min_participants=10, max_participants=25` → toast → card muncul, selected
4. Tambah variant kedua (Privat) → klik card lain → form switch ke variant pertama
5. Edit normal_price → save → toast → card update
6. Toggle inactive → konfirm → card opacity → tetap di list dgn status inactive
7. Input min_price > normal_price → inline error muncul, Save disabled
8. Login `facilitator` → tab Variants → no Add button, form read-only

### Done Criteria
- [ ] Variants tab functional (replace placeholder)
- [ ] List + Create + Edit + Toggle berjalan
- [ ] Schema test pass (6 cases)
- [ ] Permission gates berfungsi (3 visible roles + 1 hidden role smoke)
- [ ] typecheck + vitest hijau
- [ ] 8 manual smoke skenario pass

---

## §7 Risks

| Risk | Mitigasi |
|---|---|
| `coursetype` matrix entries belum lengkap | Plan Task 0: verify + tambah jika perlu |
| Backend `toggle` semantics (toggle vs set status?) | Plan Task 0: grep `toggle_coursetype/handler.go` untuk tahu apakah idempotent |
| `extra_docs` format backend (JSON vs CSV)? | Plan Task 0: grep handler list endpoint untuk tahu encoding |
| `created_at`/`updated_at` tidak ada di response | Defensive parse di hook; gunakan `?` di type kalau optional |
| Currency hard-code IDR | Acceptable — multi-currency belum scope |
| Rupiah formatting UX | Defer; native number input cukup |

---

## §8 Next Steps

1. User review spec
2. Approved → invoke `superpowers:writing-plans` skill untuk plan implementasi Iter 1B
3. Setelah Iter 1B merged → brainstorm Iter 1C (Versions / CourseVersion + CourseModule)
