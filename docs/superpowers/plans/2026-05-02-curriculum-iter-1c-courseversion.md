# Curriculum Iter 1C — CourseVersion (Versions Tab) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aktifkan Versions tab di CourseDetail dgn CRUD CourseVersion per CourseType (timeline + detail panel + create modal + promote workflow draft→review→approved).

**Architecture:** React-Query hooks extend `lib/api/curriculum.ts`. 4 new domain components di `portals/internal/components/curriculum/`. CourseDetail re-render block per tab. Backend endpoints scoped under CourseType: `GET/POST /curriculum/types/:typeId/versions`, single resource `/curriculum/versions/:versionId`, action `/curriculum/versions/:versionId/promote`. Approve menyebabkan backend auto-archive versi approved lain (atomic).

**Tech Stack:** React 18 + Vite + TS, React Hook Form + zod, react-query 5, vitest. Reuse primitives.

**Spec:** `docs/superpowers/specs/2026-05-02-curriculum-iter-1c-courseversion.md`.

---

## File Structure

| File | Action |
|---|---|
| `frontend/src/lib/auth/permissions.ts` | Modify (split course_creator courseversion perms — no approve) |
| `frontend/src/types/courseversion.ts` | Create |
| `frontend/src/schemas/courseversion.ts` | Create |
| `frontend/src/schemas/__tests__/courseversion.test.ts` | Create |
| `frontend/src/lib/api/curriculum.ts` | Modify (extend) |
| `frontend/src/portals/internal/components/curriculum/VersionTimeline.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/VersionDetailPanel.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/VersionForm.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/VersionsTab.tsx` | Create |
| `frontend/src/portals/internal/pages/detail/CourseDetail.tsx` | Modify (un-block Versions tab) |

---

## Task 0: Permission Matrix Adjust

**File:** `frontend/src/lib/auth/permissions.ts`

**Konteks:** `courseversion` resource sudah terdaftar. Semua role leader + course_creator punya ALL. Tapi spec membatasi `approve` (promote→approved) untuk role bukan course_creator. course_creator hanya boleh `create`, `read`, `update`, `list` (promote→review).

- [ ] **Step 0.1: Restrict course_creator courseversion perms**

Find:
```ts
[ROLES.COURSE_CREATOR]: {
  course: ALL, coursebatch: ['create', 'read', 'list'],
  coursetype: ALL, courseversion: ALL, coursemodule: ALL,
},
```

Replace with:
```ts
[ROLES.COURSE_CREATOR]: {
  course: ALL, coursebatch: ['create', 'read', 'list'],
  coursetype: ALL,
  courseversion: ['create', 'read', 'update', 'list'],
  coursemodule: ALL,
},
```

- [ ] **Step 0.2: Verify**

```
cd frontend && npm run typecheck && npm test
```
Expected: typecheck pass; existing tests still pass.

- [ ] **Step 0.3: Commit**

```bash
git add frontend/src/lib/auth/permissions.ts
git commit -m "feat(auth): restrict course_creator from approving courseversion"
```

---

## Task 1: Types

**File:** `frontend/src/types/courseversion.ts`

- [ ] **Step 1.1: Create type file**

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

- [ ] **Step 1.2: Typecheck + commit**

```
cd frontend && npm run typecheck
```

```bash
git add frontend/src/types/courseversion.ts
git commit -m "feat(curriculum): add CourseVersion type"
```

---

## Task 2: Schema (TDD)

**Files:**
- Create: `frontend/src/schemas/courseversion.ts`
- Test: `frontend/src/schemas/__tests__/courseversion.test.ts`

- [ ] **Step 2.1: Write failing test**

`frontend/src/schemas/__tests__/courseversion.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import {
  createCourseVersionSchema,
  promoteCourseVersionSchema,
  CHANGE_TYPES,
  nextVersion,
} from '../courseversion'

const VALID = {
  version_number: '1.0.0',
  change_type: 'minor' as const,
  changelog: 'Initial release with new modules',
}

describe('createCourseVersionSchema', () => {
  it('accepts valid input', () => {
    expect(createCourseVersionSchema.safeParse(VALID).success).toBe(true)
  })

  it('rejects invalid version format', () => {
    for (const bad of ['1.0', 'v1.0.0', '1.0.0-beta', 'abc']) {
      expect(createCourseVersionSchema.safeParse({ ...VALID, version_number: bad }).success).toBe(false)
    }
  })

  it('rejects changelog under 10 chars', () => {
    expect(createCourseVersionSchema.safeParse({ ...VALID, changelog: 'short' }).success).toBe(false)
  })

  it('accepts all 3 CHANGE_TYPES', () => {
    expect(CHANGE_TYPES).toHaveLength(3)
    for (const ct of CHANGE_TYPES) {
      expect(createCourseVersionSchema.safeParse({ ...VALID, change_type: ct }).success).toBe(true)
    }
  })
})

describe('promoteCourseVersionSchema', () => {
  it('rejects approved without approved_by', () => {
    const r = promoteCourseVersionSchema.safeParse({ target_status: 'approved' })
    expect(r.success).toBe(false)
  })

  it('accepts review without approved_by', () => {
    const r = promoteCourseVersionSchema.safeParse({ target_status: 'review' })
    expect(r.success).toBe(true)
  })

  it('accepts approved with approved_by uuid', () => {
    const r = promoteCourseVersionSchema.safeParse({
      target_status: 'approved',
      approved_by: '11111111-1111-1111-1111-111111111111',
    })
    expect(r.success).toBe(true)
  })
})

describe('nextVersion', () => {
  it('bumps major correctly', () => {
    expect(nextVersion('1.2.3', 'major')).toBe('2.0.0')
  })
  it('bumps minor correctly', () => {
    expect(nextVersion('1.2.3', 'minor')).toBe('1.3.0')
  })
  it('bumps patch correctly', () => {
    expect(nextVersion('1.2.3', 'patch')).toBe('1.2.4')
  })
})
```

- [ ] **Step 2.2: Run test, verify FAIL**

```
cd frontend && npm test -- courseversion
```
Expected: error — module `../courseversion` not found.

- [ ] **Step 2.3: Implement schema**

`frontend/src/schemas/courseversion.ts`:
```ts
import { z } from 'zod'
import type { ChangeType } from '@/types/courseversion'

export const CHANGE_TYPES = ['major', 'minor', 'patch'] as const
export const VERSION_STATUSES = ['draft', 'review', 'approved', 'archived'] as const
const VERSION_REGEX = /^\d+\.\d+\.\d+$/

export const createCourseVersionSchema = z.object({
  version_number: z.string().regex(VERSION_REGEX, 'Format: MAJOR.MINOR.PATCH (mis. 1.2.3)'),
  change_type: z.enum(CHANGE_TYPES),
  changelog: z.string().min(10, 'Changelog minimal 10 karakter').max(5000),
})

export const promoteCourseVersionSchema = z
  .object({
    target_status: z.enum(['review', 'approved']),
    approved_by: z.string().uuid().optional(),
  })
  .refine((d) => d.target_status !== 'approved' || !!d.approved_by, {
    message: 'approved_by wajib saat promote ke approved',
    path: ['approved_by'],
  })

export type CreateCourseVersionInput = z.infer<typeof createCourseVersionSchema>
export type PromoteCourseVersionInput = z.infer<typeof promoteCourseVersionSchema>

export function nextVersion(current: string, changeType: ChangeType): string {
  const parts = current.split('.').map((n) => Number.parseInt(n, 10))
  if (parts.length !== 3 || parts.some((n) => Number.isNaN(n))) return '1.0.0'
  const [maj, min, pat] = parts
  if (changeType === 'major') return `${maj + 1}.0.0`
  if (changeType === 'minor') return `${maj}.${min + 1}.0`
  return `${maj}.${min}.${pat + 1}`
}
```

- [ ] **Step 2.4: Run test, verify PASS**

```
cd frontend && npm test -- courseversion
```
Expected: 9 tests pass.

- [ ] **Step 2.5: Typecheck + commit**

```bash
git add frontend/src/schemas/courseversion.ts frontend/src/schemas/__tests__/courseversion.test.ts
git commit -m "feat(curriculum): add CourseVersion zod schema with promote refinement"
```

---

## Task 3: Extend curriculum hooks

**File:** `frontend/src/lib/api/curriculum.ts`

- [ ] **Step 3.1: Append CourseVersion hooks**

Append after existing CourseType hooks:

```ts
import type { CourseVersion } from '@/types/courseversion'
import type {
  CreateCourseVersionInput,
  PromoteCourseVersionInput,
} from '@/schemas/courseversion'

const VERSIONS_BASE = '/api/v1/curriculum/versions'
const TYPE_VERSIONS = (typeId: string) =>
  `/api/v1/curriculum/types/${typeId}/versions`

interface CourseVersionListResponse {
  data: CourseVersion[]
}
interface CourseVersionSingleResponse {
  data: CourseVersion
}

export function useCourseVersions(typeId: string | undefined) {
  return useQuery({
    queryKey: ['courseversions', 'list', typeId],
    queryFn: () =>
      apiClient
        .get<CourseVersionListResponse>(TYPE_VERSIONS(typeId!))
        .then((r) => r.data.data),
    enabled: !!typeId,
  })
}

export function useCourseVersion(versionId: string | undefined) {
  return useQuery({
    queryKey: ['courseversions', versionId],
    queryFn: () =>
      apiClient
        .get<CourseVersionSingleResponse>(`${VERSIONS_BASE}/${versionId}`)
        .then((r) => r.data.data),
    enabled: !!versionId,
  })
}

export function useCreateCourseVersion(typeId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCourseVersionInput) =>
      apiClient
        .post(TYPE_VERSIONS(typeId), input)
        .then((r) => r.data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['courseversions', 'list', typeId] }),
  })
}

export function usePromoteCourseVersion(typeId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (args: { versionId: string; input: PromoteCourseVersionInput }) =>
      apiClient
        .post(`${VERSIONS_BASE}/${args.versionId}/promote`, args.input)
        .then((r) => r.data),
    onSuccess: (_d, { versionId }) => {
      qc.invalidateQueries({ queryKey: ['courseversions', 'list', typeId] })
      qc.invalidateQueries({ queryKey: ['courseversions', versionId] })
    },
  })
}
```

- [ ] **Step 3.2: Typecheck + commit**

```
cd frontend && npm run typecheck
```

```bash
git add frontend/src/lib/api/curriculum.ts
git commit -m "feat(curriculum): add CourseVersion react-query hooks"
```

---

## Task 4: VersionTimeline

**File:** `frontend/src/portals/internal/components/curriculum/VersionTimeline.tsx`

- [ ] **Step 4.1: Implement timeline list**

```tsx
import { cn } from '@/lib/utils/cn'
import StatusBadge from '@/components/shared/StatusBadge'
import type { CourseVersion } from '@/types/courseversion'

interface Props {
  versions: CourseVersion[]
  selectedId?: string
  onSelect: (id: string) => void
}

const STATUS_VARIANT: Record<CourseVersion['status'], string> = {
  draft: 'neutral',
  review: 'warning',
  approved: 'success',
  archived: 'muted',
}

function fmtDate(s: string) {
  return new Date(s).toLocaleDateString('id-ID', { year: 'numeric', month: 'short', day: 'numeric' })
}

export default function VersionTimeline({ versions, selectedId, onSelect }: Props) {
  return (
    <div className="space-y-2">
      {versions.map((v) => {
        const selected = v.id === selectedId
        const isArchived = v.status === 'archived'
        return (
          <button
            key={v.id}
            type="button"
            onClick={() => onSelect(v.id)}
            className={cn(
              'w-full text-left p-3 rounded-lg border transition-colors',
              selected
                ? 'border-brand-600 bg-brand-50'
                : 'border-neutral-200 bg-white hover:border-neutral-300',
              isArchived && 'opacity-60',
            )}
          >
            <div className="flex items-center justify-between gap-2">
              <div className="font-medium text-sm text-neutral-900">v{v.version_number}</div>
              <StatusBadge status={v.status} variant={STATUS_VARIANT[v.status] as any} />
            </div>
            <div className="text-xs text-neutral-500 mt-1">{fmtDate(v.created_at)}</div>
            <div className="text-xs text-neutral-400 capitalize">{v.change_type}</div>
          </button>
        )
      })}
    </div>
  )
}
```

> **Note:** Jika `StatusBadge` tidak menerima prop `variant` lewat tipe tersebut, sesuaikan di Step 4.2 (cek file `components/shared/StatusBadge.tsx` aktual). Jika perlu, ganti dgn `<span className={...}>{v.status}</span>` inline berbasis `STATUS_VARIANT` map → tailwind classes.

- [ ] **Step 4.2: Verify StatusBadge API**

```
cd frontend && grep -n "export" src/components/shared/StatusBadge.tsx | head -5
```

Adjust import / props sesuai signature aktual. Kalau tidak ada `StatusBadge`, inline:
```tsx
<span className={cn(
  'px-2 py-0.5 rounded-full text-xs font-medium',
  v.status === 'draft' && 'bg-neutral-100 text-neutral-700',
  v.status === 'review' && 'bg-amber-100 text-amber-800',
  v.status === 'approved' && 'bg-green-100 text-green-800',
  v.status === 'archived' && 'bg-neutral-200 text-neutral-500',
)}>{v.status}</span>
```

- [ ] **Step 4.3: Typecheck + commit**

```
cd frontend && npm run typecheck
```

```bash
git add frontend/src/portals/internal/components/curriculum/VersionTimeline.tsx
git commit -m "feat(curriculum): add VersionTimeline component"
```

---

## Task 5: VersionDetailPanel

**File:** `frontend/src/portals/internal/components/curriculum/VersionDetailPanel.tsx`

- [ ] **Step 5.1: Implement detail panel + promote actions**

```tsx
import { toast } from 'sonner'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import RoleGate from '@/components/shared/RoleGate'
import { useCourseVersion, usePromoteCourseVersion } from '@/lib/api/curriculum'
import { useAuthStore } from '@/lib/auth/store'
import type { CourseVersion } from '@/types/courseversion'

interface Props {
  versionId: string
  typeId: string
}

function fmtDateTime(s?: string | null) {
  if (!s) return '—'
  return new Date(s).toLocaleString('id-ID')
}

export default function VersionDetailPanel({ versionId, typeId }: Props) {
  const { data: version, isLoading } = useCourseVersion(versionId)
  const promote = usePromoteCourseVersion(typeId)
  const userId = useAuthStore((s) => s.user?.id)

  if (isLoading || !version) return <LoadingSpinner size="lg" />

  async function doPromote(target: 'review' | 'approved') {
    const msg = target === 'review'
      ? 'Submit for review? Reviewer will be notified.'
      : 'Approve this version? This will archive any currently approved version.'
    if (!confirm(msg)) return
    try {
      await promote.mutateAsync({
        versionId,
        input: target === 'approved'
          ? { target_status: 'approved', approved_by: userId }
          : { target_status: 'review' },
      })
      toast.success(target === 'review' ? 'Submitted for review' : 'Version approved')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to promote version')
    }
  }

  const v: CourseVersion = version

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-lg text-neutral-900">v{v.version_number}</h3>
        <div className="flex gap-2">
          {v.status === 'draft' && (
            <RoleGate action="update" resource="courseversion">
              <Button size="sm" variant="secondary" onClick={() => doPromote('review')}>
                Submit for review
              </Button>
            </RoleGate>
          )}
          {v.status === 'review' && (
            <RoleGate action="approve" resource="courseversion">
              <Button size="sm" onClick={() => doPromote('approved')}>
                Approve
              </Button>
            </RoleGate>
          )}
        </div>
      </div>

      <dl className="grid grid-cols-2 gap-3 text-sm">
        <div>
          <dt className="text-neutral-500">Status</dt>
          <dd className="text-neutral-900 capitalize">{v.status}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Change Type</dt>
          <dd className="text-neutral-900 capitalize">{v.change_type}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Created</dt>
          <dd className="text-neutral-900">{fmtDateTime(v.created_at)}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Approved at</dt>
          <dd className="text-neutral-900">{fmtDateTime(v.approved_at)}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Approved by</dt>
          <dd className="text-neutral-900 truncate">{v.approved_by ?? '—'}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Archived at</dt>
          <dd className="text-neutral-900">{fmtDateTime(v.archived_at)}</dd>
        </div>
      </dl>

      <div>
        <div className="text-xs uppercase tracking-wide text-neutral-500 mb-1">Changelog</div>
        <pre className="whitespace-pre-wrap text-sm text-neutral-800 bg-neutral-50 p-3 rounded-lg border border-neutral-100">
{v.changelog}
        </pre>
      </div>
    </div>
  )
}
```

> **Note:** Verify `useAuthStore` import path + selector (`s.user?.id`). Jika berbeda, sesuaikan di Step 5.2.

- [ ] **Step 5.2: Verify auth store API**

```
cd frontend && grep -rn "export.*useAuthStore\|useAuthStore = " src/lib/auth/ | head -3
```

Adjust import + selector untuk dapat `user.id`.

- [ ] **Step 5.3: Typecheck + commit**

```
cd frontend && npm run typecheck
```

```bash
git add frontend/src/portals/internal/components/curriculum/VersionDetailPanel.tsx
git commit -m "feat(curriculum): add VersionDetailPanel with promote actions"
```

---

## Task 6: VersionForm

**File:** `frontend/src/portals/internal/components/curriculum/VersionForm.tsx`

- [ ] **Step 6.1: Implement create form**

```tsx
import { useEffect, useMemo, useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import {
  createCourseVersionSchema,
  CHANGE_TYPES,
  nextVersion,
  type CreateCourseVersionInput,
} from '@/schemas/courseversion'
import { useCreateCourseVersion } from '@/lib/api/curriculum'
import type { CourseVersion, ChangeType } from '@/types/courseversion'

interface Props {
  typeId: string
  latestVersion?: CourseVersion
  onSuccess: () => void
  onCancel: () => void
}

export default function VersionForm({ typeId, latestVersion, onSuccess, onCancel }: Props) {
  const create = useCreateCourseVersion(typeId)
  const [manual, setManual] = useState(false)

  const baseVersion = latestVersion?.version_number ?? '0.0.0'

  const {
    register, handleSubmit, watch, setValue,
    formState: { errors, isSubmitting },
  } = useForm<CreateCourseVersionInput>({
    resolver: zodResolver(createCourseVersionSchema),
    defaultValues: {
      change_type: 'patch',
      version_number: nextVersion(baseVersion, 'patch'),
      changelog: '',
    },
  })

  const changeType = watch('change_type') as ChangeType

  useEffect(() => {
    if (!manual) {
      setValue('version_number', nextVersion(baseVersion, changeType), { shouldValidate: true })
    }
  }, [changeType, manual, baseVersion, setValue])

  async function onSubmit(values: CreateCourseVersionInput) {
    try {
      await create.mutateAsync(values)
      toast.success('Version created')
      onSuccess()
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create version')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="font-semibold text-neutral-900">New Version</h3>

      <FormField label="Change Type" required error={errors.change_type?.message}>
        <Select {...register('change_type')}>
          {CHANGE_TYPES.map((c) => <option key={c} value={c}>{c}</option>)}
        </Select>
      </FormField>

      <FormField
        label="Version Number"
        required
        error={errors.version_number?.message}
        hint={!manual ? `Auto-suggested from ${baseVersion}. Click "Edit manually" to override.` : undefined}
      >
        <div className="flex gap-2">
          <Input
            {...register('version_number')}
            readOnly={!manual}
            className={!manual ? 'bg-neutral-50' : undefined}
          />
          <Button type="button" variant="secondary" size="sm" onClick={() => setManual((m) => !m)}>
            {manual ? 'Auto' : 'Edit manually'}
          </Button>
        </div>
      </FormField>

      <FormField label="Changelog" required error={errors.changelog?.message}>
        <textarea
          {...register('changelog')}
          rows={6}
          className="w-full p-2 border border-neutral-200 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
          placeholder="Describe what changed in this version (min 10 characters)"
        />
      </FormField>

      <div className="flex gap-2 pt-2 border-t border-neutral-100">
        <Button type="button" variant="secondary" onClick={onCancel}>Cancel</Button>
        <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>Create</Button>
      </div>
    </form>
  )
}
```

> **Note:** `FormField` `hint` prop — verify available. Jika tidak ada, hapus `hint` line dan render hint manual di bawah Input.

- [ ] **Step 6.2: Typecheck + commit**

```
cd frontend && npm run typecheck
```

```bash
git add frontend/src/portals/internal/components/curriculum/VersionForm.tsx
git commit -m "feat(curriculum): add VersionForm with auto-suggest version_number"
```

---

## Task 7: VersionsTab

**File:** `frontend/src/portals/internal/components/curriculum/VersionsTab.tsx`

- [ ] **Step 7.1: Implement tab container**

```tsx
import { useMemo, useState } from 'react'
import { Plus } from 'lucide-react'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import Select from '@/components/ui/Select'
import { useRBAC } from '@/lib/auth/useRBAC'
import { useCourseTypes, useCourseVersions } from '@/lib/api/curriculum'
import VersionTimeline from './VersionTimeline'
import VersionDetailPanel from './VersionDetailPanel'
import VersionForm from './VersionForm'
import type { CourseVersion } from '@/types/courseversion'

interface Props {
  courseId: string
}

const STATUS_RANK: Record<CourseVersion['status'], number> = {
  approved: 0, review: 1, draft: 2, archived: 3,
}

function sortVersions(list: CourseVersion[]): CourseVersion[] {
  return [...list].sort((a, b) => {
    const r = STATUS_RANK[a.status] - STATUS_RANK[b.status]
    if (r !== 0) return r
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })
}

export default function VersionsTab({ courseId }: Props) {
  const { canAccess } = useRBAC()
  const { data: types, isLoading: typesLoading } = useCourseTypes(courseId)
  const [typeId, setTypeId] = useState<string>('')

  const effectiveTypeId = typeId || types?.[0]?.id || ''
  const { data: rawVersions, isLoading: versionsLoading } = useCourseVersions(effectiveTypeId || undefined)
  const versions = useMemo(() => sortVersions(rawVersions ?? []), [rawVersions])

  const [selectedVersionId, setSelectedVersionId] = useState<string>()
  const [creating, setCreating] = useState(false)

  if (typesLoading) return <LoadingSpinner size="lg" />

  if (!types || types.length === 0) {
    return (
      <div className="text-sm text-neutral-500 p-8 border border-dashed border-neutral-200 rounded-lg text-center">
        Create a CourseType first (Variants tab) before adding versions.
      </div>
    )
  }

  const latest = versions[0]

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <label className="text-sm text-neutral-600">Course Type:</label>
          <Select
            value={effectiveTypeId}
            onChange={(e) => { setTypeId(e.target.value); setSelectedVersionId(undefined); setCreating(false) }}
            className="min-w-[200px]"
          >
            {types.map((t) => <option key={t.id} value={t.id}>{t.type_name}</option>)}
          </Select>
        </div>
        <RoleGate action="create" resource="courseversion">
          <Button size="sm" onClick={() => { setCreating(true); setSelectedVersionId(undefined) }}>
            <Plus className="w-4 h-4" /> Create New Version
          </Button>
        </RoleGate>
      </div>

      {/* Body */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left: timeline */}
        <div className="lg:col-span-1">
          {versionsLoading ? (
            <LoadingSpinner size="md" />
          ) : versions.length === 0 ? (
            <div className="text-sm text-neutral-500 p-4 border border-dashed border-neutral-200 rounded-lg text-center">
              No versions yet.
              {canAccess('create', 'courseversion') && ' Create the first version.'}
            </div>
          ) : (
            <VersionTimeline
              versions={versions}
              selectedId={selectedVersionId}
              onSelect={(id) => { setSelectedVersionId(id); setCreating(false) }}
            />
          )}
        </div>

        {/* Right: detail or create form */}
        <div className="lg:col-span-2 bg-white border border-neutral-100 rounded-xl p-5">
          {creating ? (
            <VersionForm
              typeId={effectiveTypeId}
              latestVersion={latest}
              onSuccess={() => setCreating(false)}
              onCancel={() => setCreating(false)}
            />
          ) : selectedVersionId ? (
            <VersionDetailPanel versionId={selectedVersionId} typeId={effectiveTypeId} />
          ) : (
            <div className="text-sm text-neutral-500 p-8 text-center">
              {versions.length === 0
                ? 'Click + Create New Version to start.'
                : 'Select a version to see details.'}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 7.2: Typecheck + commit**

```
cd frontend && npm run typecheck
```

```bash
git add frontend/src/portals/internal/components/curriculum/VersionsTab.tsx
git commit -m "feat(curriculum): add VersionsTab container with type selector"
```

---

## Task 8: Wire VersionsTab into CourseDetail

**File:** `frontend/src/portals/internal/pages/detail/CourseDetail.tsx`

- [ ] **Step 8.1: Add import**

After existing import for `VariantsTab`:
```tsx
import VersionsTab from '@/portals/internal/components/curriculum/VersionsTab'
```

- [ ] **Step 8.2: Update handleTabChange**

Find:
```tsx
function handleTabChange(v: string) {
  if (v === 'overview' || v === 'variants') setTab(v)
  // versions/cert/settings remain disabled until iter 1C/1D/1E
}
```

Replace with:
```tsx
function handleTabChange(v: string) {
  if (v === 'overview' || v === 'variants' || v === 'versions') setTab(v)
  // cert/settings remain disabled until iter 1D/1E
}
```

- [ ] **Step 8.3: Add render block**

After `{tab === 'variants' && ...}`, add:
```tsx
{tab === 'versions' && <VersionsTab courseId={id} />}
```

- [ ] **Step 8.4: Typecheck + tests**

```
cd frontend && npm run typecheck && npm test
```
Expected: typecheck pass; previous tests + 9 new schema tests pass.

- [ ] **Step 8.5: Commit**

```bash
git add frontend/src/portals/internal/pages/detail/CourseDetail.tsx
git commit -m "feat(curriculum): wire VersionsTab into CourseDetail"
```

---

## Task 9: Smoke Verify

- [ ] **Step 9.1: Run dev server**

```
cd frontend && npm run dev
```

- [ ] **Step 9.2: Manual smoke (10 skenario)**

Login `dept_leader`. Navigate to MasterCourse detail (`/internal/courses/:id`):

1. [ ] Click tab `Versions` → kalau belum ada CourseType: empty state "Create a CourseType first"
2. [ ] Setelah ada CourseType: dropdown muncul; jika belum ada version → empty state + CTA visible
3. [ ] Click `+ Create New Version` → form muncul, default `change_type=patch`, `version_number=0.0.1` (auto-suggested dari 0.0.0)
4. [ ] Pilih `change_type=minor` → version_number berubah ke `0.1.0` otomatis
5. [ ] Submit dgn changelog "Initial release with new modules" → toast → list refresh, status `draft`
6. [ ] Click version di timeline → detail panel render lengkap
7. [ ] Click "Submit for review" → confirm → status `review`, button berubah jadi "Approve"
8. [ ] Click "Approve" → confirm → status `approved`, `approved_at` + `approved_by` terisi
9. [ ] Buat versi kedua, promote review→approved → versi pertama otomatis `archived` (refresh list memperlihatkan)
10. [ ] Login `course_creator` → bisa create + Submit for review, TIDAK ada tombol Approve (RoleGate hide). Login `facilitator` → no create button, no promote button (read-only)

- [ ] **Step 9.3: Final verify**

```
cd frontend && npm run typecheck && npm test
```
Expected: typecheck clean, all tests pass.

Tidak ada commit di Task 9 kecuali ada bug yang ditemukan.

---

## Done Criteria

- [ ] Permission matrix: course_creator courseversion = `['create','read','update','list']` (no approve)
- [ ] Type + zod schema + 9 tests
- [ ] 4 react-query hooks (list, get, create, promote)
- [ ] 4 komponen baru (VersionTimeline, VersionDetailPanel, VersionForm, VersionsTab)
- [ ] CourseDetail Versions tab functional
- [ ] typecheck clean, vitest hijau
- [ ] 10 manual smoke pass
- [ ] All commits on `feat/curriculum-iter-1c`

Setelah merge → brainstorm Iter 1D (CourseModule — list/CRUD modules dlm version, drag-reorder).
