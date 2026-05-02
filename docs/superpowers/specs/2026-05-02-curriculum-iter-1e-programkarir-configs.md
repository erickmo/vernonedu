# Curriculum Iter 1E — Program Karir Configs (Internship + CharacterTest)

**Date:** 2026-05-02
**Type:** Implementation spec (Fase 1 Curriculum, Iterasi 1E)
**Roadmap:** `docs/superpowers/specs/2026-05-02-frontend-crud-parity-roadmap.md` Bucket 1
**Predecessor:** `docs/superpowers/specs/2026-05-02-curriculum-iter-1d-coursemodule.md`
**Status:** Draft → User Review

---

## §1 Purpose & Scope

### Tujuan
Tambah InternshipConfig + CharacterTestConfig forms inline dalam `VersionDetailPanel`. Visible hanya saat CourseType program-karir.

### In-scope
- `ProgramKarirSection` di bawah `ModulesSection`
- Hidden jika CourseType bukan Program Karir
- Internship form: PartnerCompanyName, PositionTitle, DurationWeeks, SupervisorName/Contact, MOUDocumentURL, IsCompanyProvided
- CharacterTest form: TestType, TestProvider, PassingThreshold (0-100), TalentpoolEligible
- Both upsert via PUT (no delete)
- Lock saat version status approved/archived (sama dgn modules)

### Out-of-scope
- CertificateTemplate management → iter 1F (global page)
- Reference modules → iter 1G
- ComponentFailureConfig → iter 1G
- PartnerCompanyID picker (pakai free-text + opsi UUID, picker defer)
- SubmitTestResult (dipakai siswa, bukan internal portal)

### Detection — "Program Karir" CourseType
- Match by `course_type.type_name` mengandung "Karir" / "karir" (case-insensitive). Iter 1B menyimpan free-text type_name dgn enum dropdown — value "Program Karir" muncul di TYPE_NAMES.
- Helper: `isProgramKarir(typeName: string): boolean`

---

## §2 Architecture & Components

### File Map

| File | Action |
|---|---|
| `frontend/src/types/internshipconfig.ts` | Create |
| `frontend/src/types/charactertestconfig.ts` | Create |
| `frontend/src/schemas/internshipconfig.ts` | Create |
| `frontend/src/schemas/charactertestconfig.ts` | Create |
| `frontend/src/schemas/__tests__/programkarir.test.ts` | Create (combined tests) |
| `frontend/src/lib/api/curriculum.ts` | Modify (extend +4 hooks) |
| `frontend/src/lib/utils/coursetype.ts` | Create (`isProgramKarir`) |
| `frontend/src/portals/internal/components/curriculum/InternshipConfigForm.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/CharacterTestConfigForm.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/ProgramKarirSection.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/VersionDetailPanel.tsx` | Modify (render ProgramKarirSection) |

### Reuse
`FormField`, `Input`, `Select`, `Textarea`, `Button`, `RoleGate`, `LoadingSpinner`. Tidak butuh shared component baru.

### Data Flow
```
VersionDetailPanel(version, typeId)
  ├── (existing)
  └── ProgramKarirSection(version, courseType?)
        ├── (skip render kalau !isProgramKarir(courseType.type_name))
        ├── InternshipConfigForm(versionId, locked)
        │     ├── useInternshipConfig(versionId) → existing or null
        │     └── useUpsertInternshipConfig(versionId)
        └── CharacterTestConfigForm(versionId, locked)
              ├── useCharacterTestConfig(versionId)
              └── useUpsertCharacterTestConfig(versionId)
```

ProgramKarirSection butuh CourseType info. Cara terpendek: pass `courseTypeName` prop dari parent. VersionDetailPanel saat ini hanya tahu `typeId`. Solusi: pass `typeName?: string` baru dari `VersionsTab` ke `VersionDetailPanel` (bersamaan dgn typeId).

### Permission
| Action | Resource | Catatan |
|---|---|---|
| `read` | `internshipconfig` / `charactertestconfig` | semua role yg punya entries |
| `update` | `internshipconfig` / `charactertestconfig` | dept_leader, course_creator, leader roles |

`internshipconfig` + `charactertestconfig` resources sudah di matrix (verify Plan Task 0).

---

## §3 UI Layout

```
─── VersionDetailPanel ────────────────────────────────────────────
[v1.2.0 header + status + promote button]
[Status / Change Type / dates table]
[Changelog]
[Modules section]   ← iter 1D
─────────────────────────────────────────────────────────────────
Program Karir Configuration                     ← iter 1E header
─────────────────────────────────────────────────────────────────
┌─ Internship ────────────────────────────────────────────────────┐
│ Partner Company* [_____________]   Position Title* [_________] │
│ Duration Weeks*  [__]              Supervisor Name [_________] │
│ Supervisor Contact [____________]  MOU Document URL [________] │
│ ☐ Is Company Provided                                          │
│                                              [Save Internship] │
└────────────────────────────────────────────────────────────────┘
┌─ Character Test ───────────────────────────────────────────────┐
│ Test Type*       [DISC ▼]    Test Provider     [_____________] │
│ Passing Threshold (0-100) [__]                                  │
│ ☐ Talentpool Eligible                                          │
│                                       [Save Character Test]    │
└────────────────────────────────────────────────────────────────┘
```

### Lock state
Inputs disabled, save button hidden, replaced by "🔒 Read-only" badge.

### Empty (no existing config)
Form shows blank inputs. PUT creates on first save.

### Saved confirmation
Toast "Internship config saved" / "Character test config saved" + form values stick.

---

## §4 Schema, Types, API

### Type — `frontend/src/types/internshipconfig.ts`
```ts
export interface InternshipConfig {
  id: string
  course_version_id: string
  partner_company_name: string
  partner_company_id?: string | null
  position_title: string
  duration_weeks: number
  supervisor_name: string
  supervisor_contact: string
  mou_document_url: string
  is_company_provided: boolean
}
```

### Type — `frontend/src/types/charactertestconfig.ts`
```ts
export interface CharacterTestConfig {
  id: string
  course_version_id: string
  test_type: string
  test_provider: string
  passing_threshold: number
  talentpool_eligible: boolean
}
```

### Schemas
```ts
// internshipconfig.ts
import { z } from 'zod'

export const upsertInternshipConfigSchema = z.object({
  partner_company_name: z.string().min(1, 'Partner wajib').max(200),
  partner_company_id: z.string().uuid().optional().or(z.literal('')),
  position_title: z.string().min(1, 'Position wajib').max(200),
  duration_weeks: z.number().int().positive(),
  supervisor_name: z.string().max(200).default(''),
  supervisor_contact: z.string().max(200).default(''),
  mou_document_url: z.string().url('URL tidak valid').or(z.literal('')).default(''),
  is_company_provided: z.boolean().default(false),
})
export type UpsertInternshipConfigInput = z.infer<typeof upsertInternshipConfigSchema>
```

```ts
// charactertestconfig.ts
import { z } from 'zod'

export const TEST_TYPES = ['DISC', 'MBTI', 'Big5', 'Custom'] as const

export const upsertCharacterTestConfigSchema = z.object({
  test_type: z.string().min(1, 'Test type wajib').max(100),
  test_provider: z.string().max(200).default(''),
  passing_threshold: z.number().min(0).max(100),
  talentpool_eligible: z.boolean().default(false),
})
export type UpsertCharacterTestConfigInput = z.infer<typeof upsertCharacterTestConfigSchema>
```

### API Endpoints
| Method | Path |
|---|---|
| GET | `/api/v1/curriculum/versions/{versionID}/internship` |
| PUT | `/api/v1/curriculum/versions/{versionID}/internship` |
| GET | `/api/v1/curriculum/versions/{versionID}/character-test` |
| PUT | `/api/v1/curriculum/versions/{versionID}/character-test` |

### React-Query Hooks (4)
```
useInternshipConfig(versionId)              // ['internshipconfig', versionId]
useUpsertInternshipConfig(versionId)        // PUT, invalidate above
useCharacterTestConfig(versionId)           // ['charactertestconfig', versionId]
useUpsertCharacterTestConfig(versionId)     // PUT, invalidate above
```

`GET` dapat 404 saat config belum ada — hook harus handle gracefully (treat 404 as `null`).

### Helper — `frontend/src/lib/utils/coursetype.ts`
```ts
export function isProgramKarir(typeName?: string | null): boolean {
  if (!typeName) return false
  return typeName.toLowerCase().includes('karir')
}
```

---

## §5 Testing & Done Criteria

### Unit Tests (vitest) — `programkarir.test.ts`
1. internship: accepts valid input
2. internship: rejects empty partner_company_name
3. internship: rejects duration_weeks ≤ 0
4. internship: accepts empty mou_document_url
5. internship: rejects invalid URL when provided
6. character: accepts all TEST_TYPES
7. character: rejects passing_threshold < 0 or > 100
8. character: accepts threshold=0 and threshold=100 (boundary)
9. `isProgramKarir('Program Karir')` === true, `isProgramKarir('Reguler')` === false, `isProgramKarir('')` === false

### Manual Smoke (10 skenario)
1. Login dept_leader → CourseDetail dgn CourseType "Reguler" → Versions → pilih version → tidak ada Program Karir section
2. Switch Versions selector ke CourseType "Program Karir" → version → section muncul
3. Internship form kosong → fill valid data → Save → toast → reload page → values persist
4. Tambah satu field optional → Save → values update
5. Submit invalid url di mou_document_url → inline error
6. Submit duration_weeks=0 → inline error
7. Character form: pilih test_type=DISC → set threshold=75 → check talentpool → Save → toast
8. Threshold=120 → inline error "min 0, max 100"
9. Switch ke version approved → kedua form jadi disabled, Save button hidden, lock badge muncul
10. Login facilitator → kedua form read-only (no Save)

### Done Criteria
- [ ] 2 types + 2 schemas + 9 tests
- [ ] 4 hooks + utility `isProgramKarir`
- [ ] 3 components (InternshipForm, CharacterTestForm, ProgramKarirSection)
- [ ] VersionDetailPanel renders ProgramKarirSection (with typeName prop wired from VersionsTab)
- [ ] Lock policy berlaku
- [ ] typecheck clean, vitest hijau
- [ ] 10 smoke skenario pass

---

## §6 Risks

| Risk | Mitigasi |
|---|---|
| 404 saat GET config kosong | Hook tangani — return `null` instead of throw |
| `typeName` not piped from VersionsTab | Plan Task 0: tambah prop |
| `partner_company_id` UUID picker missing | Free-text optional. Picker defer. |
| Permission resources missing | Plan Task 0: verify + tambah `internshipconfig`/`charactertestconfig` jika belum |
| Backend backwards-compat saat field baru | Out of scope — pakai existing fields only |
| Re-render perf akibat 2 useQuery + 2 useMutation | Acceptable, tidak banyak data |

---

## §7 Next Steps

1. User review spec
2. Approved → invoke `superpowers:writing-plans` skill untuk plan implementasi Iter 1E
3. Setelah merge → Iter 1F (CertificateTemplate global mgmt) atau Bucket 2 (Operations)
