# Frontend CRUD Parity — Prerequisite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Siapkan fondasi permission helper, role coverage lengkap, dan dokumen konvensi CRUD agar fase 1 (Curriculum) dapat dimulai tanpa hambatan struktural.

**Architecture:** Reuse primitif yang sudah ada (`DataTable`, `FormField`, `FormModal`, `StandardPageLayout`, react-query, react-hook-form, zod). Tambahkan: (1) `canAccess(action, resource)` helper terpusat, (2) extend `useRBAC` dengan 11 staff role + 2 external role, (3) dokumen konvensi pola Partner sebagai referensi domain berikutnya.

**Tech Stack:** React 18 + Vite + TS, React Query 5, react-hook-form + zod, shadcn-style UI primitives, Tailwind, lucide-react.

**Spec reference:** `docs/superpowers/specs/2026-05-02-frontend-crud-parity-roadmap.md` (§5 Conventions, §6 Open Questions #1–3).

---

## File Structure

| File | Status | Responsibility |
|---|---|---|
| `frontend/src/lib/auth/roles.ts` | Create | Constants: semua role keys + label + grouping |
| `frontend/src/lib/auth/permissions.ts` | Create | `canAccess(action, resource)` matrix |
| `frontend/src/lib/auth/useRBAC.ts` | Modify | Tambah getter per role, accept multi-role check |
| `frontend/src/lib/auth/__tests__/permissions.test.ts` | Create | Unit test matrix |
| `frontend/src/components/shared/RoleGate.tsx` | Create | Component wrapper untuk conditional render by permission |
| `docs/frontend/CRUD-CONVENTIONS.md` | Create | Pola Partner sbg template, file location, naming, variation policy |

Tidak ada file yang dihapus. Tidak ada migrasi page existing dalam plan ini.

---

## Pre-flight Check

- [ ] **Step 0.1: Verify dev environment**

Run: `cd frontend && npm install && npm run typecheck`
Expected: install sukses, typecheck pass.

- [ ] **Step 0.2: Verify test runner**

Frontend belum punya test runner terinstal. Install vitest:

Run: `cd frontend && npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom`
Expected: deps terpasang.

Tambah ke `frontend/package.json` script:
```json
"test": "vitest run",
"test:watch": "vitest"
```

Buat `frontend/vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  test: {
    environment: 'jsdom',
    globals: true,
  },
})
```

Run: `npm test`
Expected: "No test files found" (belum ada test, OK).

- [ ] **Step 0.3: Commit pre-flight**

```bash
git add frontend/package.json frontend/package-lock.json frontend/vitest.config.ts
git commit -m "chore(frontend): add vitest test runner"
```

---

## Task 1: Centralized Role Constants

**Files:**
- Create: `frontend/src/lib/auth/roles.ts`

- [ ] **Step 1.1: Create roles module**

Isi `frontend/src/lib/auth/roles.ts`:
```ts
export const ROLES = {
  // External
  STUDENT: 'student',
  FRANCHISEE: 'franchisee',
  // Staff — leadership
  DIRECTOR: 'director',
  CEO: 'ceo',
  // Staff — education
  EDUCATION_LEADER: 'education_leader',
  DEPT_LEADER: 'dept_leader',
  COURSE_OWNER: 'course_owner',
  COURSE_CREATOR: 'course_creator',
  FACILITATOR: 'facilitator',
  ACADEMIC_LEADER: 'academic_leader',
  // Staff — operations
  OPERATION_LEADER: 'operation_leader',
  OPERATION_ADMIN: 'operation_admin',
  CUSTOMER_SERVICE: 'customer_service',
  MARKETING: 'marketing',
  // Staff — accounting
  ACCOUNTING_LEADER: 'accounting_leader',
  ACCOUNTING_STAFF: 'accounting_staff',
  FINANCE: 'finance',
  // Misc
  ADMIN: 'admin',
  VERNONEDU_ADMIN: 'vernonedu_admin',
} as const

export type Role = typeof ROLES[keyof typeof ROLES]

export const STAFF_ROLES: Role[] = [
  ROLES.DIRECTOR, ROLES.CEO, ROLES.EDUCATION_LEADER, ROLES.DEPT_LEADER,
  ROLES.COURSE_OWNER, ROLES.COURSE_CREATOR, ROLES.FACILITATOR, ROLES.ACADEMIC_LEADER,
  ROLES.OPERATION_LEADER, ROLES.OPERATION_ADMIN, ROLES.CUSTOMER_SERVICE, ROLES.MARKETING,
  ROLES.ACCOUNTING_LEADER, ROLES.ACCOUNTING_STAFF, ROLES.FINANCE,
  ROLES.ADMIN, ROLES.VERNONEDU_ADMIN,
]

export const ROLE_LABELS: Record<Role, string> = {
  student: 'Siswa',
  franchisee: 'Franchisee',
  director: 'Direktur',
  ceo: 'CEO',
  education_leader: 'Education Leader',
  dept_leader: 'Department Leader',
  course_owner: 'Course Owner',
  course_creator: 'Course Creator',
  facilitator: 'Fasilitator',
  academic_leader: 'Academic Leader',
  operation_leader: 'Operation Leader',
  operation_admin: 'Operation Admin',
  customer_service: 'Customer Service',
  marketing: 'Marketing',
  accounting_leader: 'Accounting Leader',
  accounting_staff: 'Accounting Staff',
  finance: 'Finance',
  admin: 'Admin',
  vernonedu_admin: 'Platform Admin',
}
```

- [ ] **Step 1.2: Typecheck**

Run: `cd frontend && npm run typecheck`
Expected: pass.

- [ ] **Step 1.3: Commit**

```bash
git add frontend/src/lib/auth/roles.ts
git commit -m "feat(auth): add centralized role constants and labels"
```

---

## Task 2: Permission Matrix Helper

**Files:**
- Create: `frontend/src/lib/auth/permissions.ts`
- Test: `frontend/src/lib/auth/__tests__/permissions.test.ts`

- [ ] **Step 2.1: Write failing test**

Isi `frontend/src/lib/auth/__tests__/permissions.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { canAccess } from '../permissions'
import { ROLES } from '../roles'

describe('canAccess', () => {
  it('director can do anything on any resource', () => {
    expect(canAccess(ROLES.DIRECTOR, 'create', 'mastercourse')).toBe(true)
    expect(canAccess(ROLES.DIRECTOR, 'delete', 'enrollment')).toBe(true)
  })

  it('dept_leader can manage curriculum but not accounting', () => {
    expect(canAccess(ROLES.DEPT_LEADER, 'create', 'mastercourse')).toBe(true)
    expect(canAccess(ROLES.DEPT_LEADER, 'create', 'transaction')).toBe(false)
  })

  it('facilitator can only mark attendance', () => {
    expect(canAccess(ROLES.FACILITATOR, 'update', 'attendance')).toBe(true)
    expect(canAccess(ROLES.FACILITATOR, 'create', 'mastercourse')).toBe(false)
  })

  it('student can read own enrollment', () => {
    expect(canAccess(ROLES.STUDENT, 'read', 'enrollment.own')).toBe(true)
    expect(canAccess(ROLES.STUDENT, 'create', 'enrollment')).toBe(false)
  })

  it('unknown role returns false', () => {
    expect(canAccess('ghost' as any, 'read', 'mastercourse')).toBe(false)
  })

  it('unknown resource returns false', () => {
    expect(canAccess(ROLES.DIRECTOR, 'read', 'unicorn' as any)).toBe(false)
  })
})
```

- [ ] **Step 2.2: Run test (fails)**

Run: `cd frontend && npm test`
Expected: FAIL — `canAccess` not defined.

- [ ] **Step 2.3: Implement permissions module**

Isi `frontend/src/lib/auth/permissions.ts`:
```ts
import { ROLES, type Role } from './roles'

export type Action = 'create' | 'read' | 'update' | 'delete' | 'approve' | 'list'

export type Resource =
  // Curriculum
  | 'mastercourse' | 'coursetype' | 'courseversion' | 'coursemodule'
  | 'certificatetemplate' | 'internshipconfig' | 'charactertestconfig' | 'course'
  // Operations
  | 'coursebatch' | 'batchschedule' | 'building' | 'room' | 'holiday'
  | 'attendance' | 'facilitator_assignment'
  // Enrollment & Cert
  | 'enrollment' | 'enrollment.own' | 'invoice' | 'certificate' | 'certificate.own'
  | 'lead' | 'studentappaccess' | 'crmlog'
  // Accounting
  | 'coa' | 'finance_account' | 'transaction' | 'journal_entry' | 'payable'
  | 'report' | 'budget_vs_actual' | 'commission' | 'financial_alerts'
  // BizDev
  | 'bmc' | 'okr' | 'investment_plan' | 'delegation' | 'approval'
  | 'branch' | 'mou' | 'project'
  // Marketing & CMS
  | 'cms_page' | 'cms_article' | 'cms_faq' | 'cms_testimonial' | 'cms_media'
  | 'marketing_post' | 'classdoc_post' | 'referral_partner'
  // HR & Settings
  | 'user' | 'facilitator_levels' | 'commission_config' | 'settings'
  | 'notification' | 'talentpool' | 'item' | 'canvas' | 'designthinking'

type Matrix = Partial<Record<Role, Partial<Record<Resource, Action[]>>>>

const ALL: Action[] = ['create', 'read', 'update', 'delete', 'approve', 'list']

const MATRIX: Matrix = {
  [ROLES.DIRECTOR]: { '*' as Resource: ALL } as Partial<Record<Resource, Action[]>>,
  [ROLES.CEO]: { '*' as Resource: ALL } as Partial<Record<Resource, Action[]>>,
  [ROLES.ADMIN]: { '*' as Resource: ALL } as Partial<Record<Resource, Action[]>>,
  [ROLES.VERNONEDU_ADMIN]: { '*' as Resource: ALL } as Partial<Record<Resource, Action[]>>,

  [ROLES.EDUCATION_LEADER]: {
    mastercourse: ALL, coursetype: ALL, courseversion: ALL, coursemodule: ALL,
    certificatetemplate: ALL, internshipconfig: ALL, charactertestconfig: ALL,
    course: ALL, coursebatch: ALL, certificate: ALL, talentpool: ALL,
  },
  [ROLES.ACADEMIC_LEADER]: {
    mastercourse: ALL, coursetype: ALL, courseversion: ALL, coursemodule: ALL,
    course: ALL, coursebatch: ALL, talentpool: ALL,
  },
  [ROLES.DEPT_LEADER]: {
    mastercourse: ALL, coursetype: ALL, courseversion: ALL, coursemodule: ALL,
    course: ALL, coursebatch: ALL, certificate: ['create', 'read', 'list', 'approve'],
    talentpool: ALL, approval: ['read', 'approve', 'list'],
  },
  [ROLES.COURSE_OWNER]: {
    course: ALL, coursebatch: ALL, courseversion: ['read', 'list'],
    coursemodule: ['read', 'list'], enrollment: ['read', 'list'],
  },
  [ROLES.COURSE_CREATOR]: {
    course: ALL, coursebatch: ['create', 'read', 'list'],
    courseversion: ALL, coursemodule: ALL,
  },
  [ROLES.FACILITATOR]: {
    coursebatch: ['read', 'list'], attendance: ['create', 'read', 'update', 'list'],
    enrollment: ['read', 'list'],
  },

  [ROLES.OPERATION_LEADER]: {
    coursebatch: ALL, batchschedule: ALL, building: ALL, room: ALL, holiday: ALL,
    lead: ALL, approval: ['read', 'approve', 'list'],
  },
  [ROLES.OPERATION_ADMIN]: {
    coursebatch: ['create', 'read', 'update', 'list'],
    batchschedule: ALL, building: ALL, room: ALL, holiday: ALL,
    facilitator_assignment: ALL,
  },
  [ROLES.CUSTOMER_SERVICE]: {
    enrollment: ALL, invoice: ['create', 'read', 'list'], lead: ALL,
    crmlog: ALL, studentappaccess: ['create', 'read', 'list'],
  },
  [ROLES.MARKETING]: {
    lead: ALL, marketing_post: ALL, classdoc_post: ALL, referral_partner: ALL,
    cms_page: ALL, cms_article: ALL, cms_faq: ALL, cms_testimonial: ALL, cms_media: ALL,
  },

  [ROLES.ACCOUNTING_LEADER]: {
    coa: ALL, finance_account: ALL, transaction: ALL, journal_entry: ALL,
    payable: ALL, report: ALL, budget_vs_actual: ALL,
    commission: ALL, financial_alerts: ALL, invoice: ALL,
  },
  [ROLES.ACCOUNTING_STAFF]: {
    transaction: ALL, journal_entry: ['create', 'read', 'list'],
    payable: ['create', 'read', 'update', 'list'], invoice: ALL,
    finance_account: ['read', 'list'],
  },
  [ROLES.FINANCE]: {
    transaction: ALL, payable: ALL, invoice: ALL, report: ALL,
    budget_vs_actual: ALL,
  },

  [ROLES.STUDENT]: {
    'enrollment.own': ['read', 'list'], 'certificate.own': ['read', 'list'],
    canvas: ALL, designthinking: ALL,
  },
  [ROLES.FRANCHISEE]: {
    coursebatch: ['read', 'list'], enrollment: ['read', 'list'],
    invoice: ['read', 'list'], user: ['read', 'list'],
  },
}

export function canAccess(role: Role | string | null | undefined, action: Action, resource: Resource): boolean {
  if (!role) return false
  const perms = MATRIX[role as Role]
  if (!perms) return false
  const wildcard = (perms as any)['*'] as Action[] | undefined
  if (wildcard?.includes(action)) return true
  const actions = perms[resource]
  return Array.isArray(actions) && actions.includes(action)
}
```

- [ ] **Step 2.4: Run test (passes)**

Run: `cd frontend && npm test`
Expected: PASS, all 6 tests green.

- [ ] **Step 2.5: Commit**

```bash
git add frontend/src/lib/auth/permissions.ts frontend/src/lib/auth/__tests__/permissions.test.ts
git commit -m "feat(auth): add canAccess permission matrix"
```

---

## Task 3: Extend useRBAC

**Files:**
- Modify: `frontend/src/lib/auth/useRBAC.ts`

- [ ] **Step 3.1: Replace useRBAC with full role coverage + canAccess integration**

Isi `frontend/src/lib/auth/useRBAC.ts` (overwrite):
```ts
import { useAuth } from './useAuth'
import { ROLES, STAFF_ROLES, type Role } from './roles'
import { canAccess as canAccessFn, type Action, type Resource } from './permissions'

export function useRBAC() {
  const { user } = useAuth()
  const role = (user?.role ?? null) as Role | null

  return {
    role,
    hasRole: (...roles: string[]) => roles.includes(role ?? ''),
    isStaff: () => role !== null && STAFF_ROLES.includes(role),
    isStudent: () => role === ROLES.STUDENT,
    isFranchisee: () => role === ROLES.FRANCHISEE,
    isDirector: () => role === ROLES.DIRECTOR || role === ROLES.CEO,
    canAccess: (action: Action, resource: Resource) => canAccessFn(role, action, resource),
  }
}
```

- [ ] **Step 3.2: Verify existing usages still compile**

Run: `cd frontend && grep -rn "useRBAC\|isAdmin\|isCEO" src --include="*.tsx" --include="*.ts"`
Expected: identifikasi konsumen. Cek tidak ada yang panggil `isAdmin()` / `isCEO()` (dihapus). Kalau ada, ganti ke `hasRole(ROLES.ADMIN)` atau `isDirector()`.

- [ ] **Step 3.3: Fix konsumen yang break (jika ada)**

Untuk tiap call `isAdmin()`, ganti `useRBAC().hasRole(ROLES.ADMIN)`. Untuk `isCEO()`, ganti `useRBAC().hasRole(ROLES.CEO)`.

- [ ] **Step 3.4: Typecheck**

Run: `cd frontend && npm run typecheck && npm test`
Expected: typecheck pass, test pass.

- [ ] **Step 3.5: Commit**

```bash
git add frontend/src/lib/auth/useRBAC.ts frontend/src
git commit -m "feat(auth): extend useRBAC with full role coverage and canAccess"
```

---

## Task 4: RoleGate Component

**Files:**
- Create: `frontend/src/components/shared/RoleGate.tsx`

- [ ] **Step 4.1: Create RoleGate**

Isi `frontend/src/components/shared/RoleGate.tsx`:
```tsx
import { ReactNode } from 'react'
import { useRBAC } from '@/lib/auth/useRBAC'
import type { Action, Resource } from '@/lib/auth/permissions'

interface Props {
  action: Action
  resource: Resource
  fallback?: ReactNode
  children: ReactNode
}

export default function RoleGate({ action, resource, fallback = null, children }: Props) {
  const { canAccess } = useRBAC()
  if (!canAccess(action, resource)) return <>{fallback}</>
  return <>{children}</>
}
```

- [ ] **Step 4.2: Typecheck**

Run: `cd frontend && npm run typecheck`
Expected: pass.

- [ ] **Step 4.3: Commit**

```bash
git add frontend/src/components/shared/RoleGate.tsx
git commit -m "feat(shared): add RoleGate component for permission-aware rendering"
```

---

## Task 5: CRUD Conventions Document

**Files:**
- Create: `docs/frontend/CRUD-CONVENTIONS.md`

- [ ] **Step 5.1: Write document**

Isi `docs/frontend/CRUD-CONVENTIONS.md`:
````markdown
# Frontend CRUD Conventions

> Referensi pola implementasi domain CRUD baru. Pakai pola Partner (`portals/internal/pages/Partners.tsx`, `PartnerCreatePage.tsx`, `PartnerEditPage.tsx`, `detail/PartnerDetail.tsx`) sebagai template.

## File Layout

```
src/
├── portals/internal/pages/
│   ├── <Domain>s.tsx                ← list page
│   ├── <Domain>CreatePage.tsx       ← create form
│   ├── <Domain>EditPage.tsx         ← edit form
│   └── detail/
│       └── <Domain>Detail.tsx       ← detail (read-only + Edit button)
├── schemas/
│   └── <domain>.ts                  ← zod schema + TS type
├── types/
│   └── <domain>.ts                  ← API response types
└── lib/api/
    └── <bucket>.ts                  ← react-query hooks (use<Domain>List, use<Domain>, use<Domain>Mutations)
```

## Routing

Daftarkan di `src/App.tsx` di blok `/internal`. **PENTING:** route `/new` dan `/edit` HARUS sebelum `/:id` (lihat commit `ec440578`):

```tsx
<Route path="<domains>" element={<DomainList />} />
<Route path="<domains>/new" element={<DomainCreatePage />} />
<Route path="<domains>/:id/edit" element={<DomainEditPage />} />
<Route path="<domains>/:id" element={<DomainDetail />} />
```

## Layout

- List: pakai `PageHeader` + `SearchInput` + `FilterTabs` + `DataTable`
- Create / Edit: pakai `StandardPageLayout` (`components/layout/StandardPageLayout`)
- Detail: pakai `DetailPageLayout` (`components/layout/DetailPageLayout`)

## Form

- Library: `react-hook-form` + `@hookform/resolvers/zod`
- Schema di `schemas/<domain>.ts`:
  ```ts
  import { z } from 'zod'
  export const createXSchema = z.object({ ... })
  export const updateXSchema = createXSchema.partial()
  export type CreateXInput = z.infer<typeof createXSchema>
  ```
- Field wrapper: `FormField` (dari `components/shared`) untuk label + error
- Primitive input: dari `components/ui/` (`Input`, `Select`, `Textarea`)

## Data Layer

- React Query 5
- Hook naming: `useXList(filters)`, `useX(id)`, `useCreateX()`, `useUpdateX()`, `useDeleteX()`
- Query key: `['<domain>', 'list', filters]`, `['<domain>', id]`
- Invalidate setelah mutation: list + single record

## Permission

- Tiap action butuh `canAccess(action, resource)` check
- Wrap tombol dengan `<RoleGate action="create" resource="<resource>">` atau cek manual di handler
- Permission matrix: `lib/auth/permissions.ts`

## Variation Policy

`StandardPageLayout` adalah default. Body bisa diganti untuk variasi (lihat spec roadmap §5):

| Variasi | Domain |
|---|---|
| Wizard multi-step | Approval, Delegation, Certificate revocation |
| Kanban | TalentPool pipeline |
| Calendar | BatchSchedule |
| Tree / hierarchy | OKR, CoA |
| Canvas grid | BMC |
| Table inline-edit | CoA, Facilitator levels, Holiday |
| Builder | CertificateTemplate, CMS Page |
| Report viewer | BS / PL / CF / GL / TB |

## Definition of Done per Domain

1. List + Detail + Create + Edit page
2. Schema + type + API hooks lengkap
3. Permission gate di tiap aksi destruktif
4. Empty / loading / error state ada
5. Manual smoke test didokumentasi di PR
6. Typecheck + lint + test pass

## Reference Implementation

Partner domain sudah lengkap:
- `src/portals/internal/pages/Partners.tsx`
- `src/portals/internal/pages/PartnerCreatePage.tsx`
- `src/portals/internal/pages/PartnerEditPage.tsx`
- `src/portals/internal/pages/detail/PartnerDetail.tsx`

Pelajari pola di file-file ini sebelum implementasi domain baru.
````

- [ ] **Step 5.2: Commit**

```bash
git add docs/frontend/CRUD-CONVENTIONS.md
git commit -m "docs(frontend): add CRUD conventions guide"
```

---

## Task 6: Smoke Verification

**Files:** none (manual)

- [ ] **Step 6.1: Run dev server**

Run: `cd frontend && npm run dev`
Expected: Vite dev server start tanpa error.

- [ ] **Step 6.2: Login + navigate Partners**

Open browser, login, navigate `/internal/partners`. Verifikasi list muncul, klik 1 partner, edit, save. Konfirmasi tidak ada regressions.

- [ ] **Step 6.3: Verify final**

Run: `cd frontend && npm run typecheck && npm run lint && npm test`
Expected: semua hijau.

- [ ] **Step 6.4: Final commit (jika ada perubahan kecil)**

```bash
git status
```
Kalau bersih, skip commit. Kalau ada perubahan, commit dengan pesan `chore(frontend): final cleanup after prerequisite`.

---

## Done Criteria

- [ ] vitest terinstal + 1 test file pass
- [ ] `roles.ts` dengan 19+ role constants
- [ ] `permissions.ts` dengan `canAccess` + matrix lengkap
- [ ] `useRBAC` extended, semua konsumen lama tetap kompatibel
- [ ] `RoleGate` component siap dipakai
- [ ] `docs/frontend/CRUD-CONVENTIONS.md` ditulis
- [ ] Partner pages tidak regressi
- [ ] typecheck + lint + test hijau

Setelah selesai → brainstorm + spec **Fase 1 Curriculum** (mulai dari MasterCourse atau CourseType).
