# Curriculum Iter 1B — CourseType (Variants Tab) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aktifkan Variants tab di CourseDetail dgn CRUD CourseType inline (master-detail layout, list cards left + form right).

**Architecture:** React-Query hooks extend `lib/api/curriculum.ts`. 3 new domain components di `portals/internal/components/curriculum/`. CourseDetail re-render block per tab. Backend endpoints scoped under MasterCourse: `GET/POST /curriculum/courses/:courseId/types`, single resource at `/curriculum/types/:typeId`. Toggle endpoint flips active/inactive (idempotent backend handles state).

**Tech Stack:** React 18 + Vite + TS, React Hook Form + zod, react-query 5, vitest. Reuse existing primitives (`MultiInput`, `FormField`, `StandardPageLayout`, `RoleGate`, etc.).

**Spec:** `docs/superpowers/specs/2026-05-02-curriculum-iter-1b-coursetype.md`.

---

## File Structure

| File | Action |
|---|---|
| `frontend/src/lib/auth/permissions.ts` | Modify (add `coursetype` entries to course_owner + course_creator) |
| `frontend/src/types/coursetype.ts` | Create |
| `frontend/src/schemas/coursetype.ts` | Create |
| `frontend/src/schemas/__tests__/coursetype.test.ts` | Create |
| `frontend/src/lib/api/curriculum.ts` | Modify (extend) |
| `frontend/src/portals/internal/components/curriculum/VariantCard.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/VariantForm.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/VariantsTab.tsx` | Create |
| `frontend/src/portals/internal/pages/detail/CourseDetail.tsx` | Modify (un-block Variants tab) |

---

## Task 0: Permission Matrix Update

**File:** `frontend/src/lib/auth/permissions.ts`

- [ ] **Step 0.1: Add `coursetype` to COURSE_OWNER and COURSE_CREATOR**

Open `frontend/src/lib/auth/permissions.ts`. Find:

```ts
[ROLES.COURSE_OWNER]: {
  course: ALL, coursebatch: ALL, courseversion: ['read', 'list'],
  coursemodule: ['read', 'list'], enrollment: ['read', 'list'],
},
```

Replace with:
```ts
[ROLES.COURSE_OWNER]: {
  course: ALL, coursebatch: ALL, coursetype: ['read', 'list'],
  courseversion: ['read', 'list'], coursemodule: ['read', 'list'],
  enrollment: ['read', 'list'],
},
```

Find:
```ts
[ROLES.COURSE_CREATOR]: {
  course: ALL, coursebatch: ['create', 'read', 'list'],
  courseversion: ALL, coursemodule: ALL,
},
```

Replace with:
```ts
[ROLES.COURSE_CREATOR]: {
  course: ALL, coursebatch: ['create', 'read', 'list'],
  coursetype: ALL, courseversion: ALL, coursemodule: ALL,
},
```

- [ ] **Step 0.2: Verify**

Run: `cd frontend && npm run typecheck && npm test`
Expected: typecheck pass; existing 14 tests still pass.

- [ ] **Step 0.3: Commit**

```bash
git add frontend/src/lib/auth/permissions.ts
git commit -m "feat(auth): grant coursetype access to course_owner and course_creator"
```

---

## Task 1: Types

**File:** `frontend/src/types/coursetype.ts`

- [ ] **Step 1.1: Create type file**

`frontend/src/types/coursetype.ts`:
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

- [ ] **Step 1.2: Typecheck + commit**

Run: `cd frontend && npm run typecheck`
Expected: pass.

```bash
git add frontend/src/types/coursetype.ts
git commit -m "feat(curriculum): add CourseType type"
```

---

## Task 2: Schema (TDD)

**Files:**
- Create: `frontend/src/schemas/coursetype.ts`
- Test: `frontend/src/schemas/__tests__/coursetype.test.ts`

- [ ] **Step 2.1: Write failing test**

`frontend/src/schemas/__tests__/coursetype.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { createCourseTypeSchema, TYPE_NAMES } from '../coursetype'

const VALID = {
  type_name: 'Reguler',
  price_type: 'one-time' as const,
  price_currency: 'IDR' as const,
  target_audience: '',
  certification_type: '',
  extra_docs: [],
  normal_price: 5000000,
  min_price: 3000000,
  min_participants: 10,
  max_participants: 25,
}

describe('createCourseTypeSchema', () => {
  it('accepts valid minimal input', () => {
    const r = createCourseTypeSchema.safeParse(VALID)
    expect(r.success).toBe(true)
  })

  it('rejects empty type_name', () => {
    const r = createCourseTypeSchema.safeParse({ ...VALID, type_name: '' })
    expect(r.success).toBe(false)
  })

  it('rejects min_price greater than normal_price', () => {
    const r = createCourseTypeSchema.safeParse({ ...VALID, min_price: 6000000, normal_price: 5000000 })
    expect(r.success).toBe(false)
    if (!r.success) {
      const issue = r.error.issues.find((i) => i.path[0] === 'min_price')
      expect(issue).toBeDefined()
    }
  })

  it('rejects min_participants greater than max_participants', () => {
    const r = createCourseTypeSchema.safeParse({ ...VALID, min_participants: 30, max_participants: 25 })
    expect(r.success).toBe(false)
    if (!r.success) {
      const issue = r.error.issues.find((i) => i.path[0] === 'min_participants')
      expect(issue).toBeDefined()
    }
  })

  it('rejects negative price', () => {
    const r = createCourseTypeSchema.safeParse({ ...VALID, normal_price: -1 })
    expect(r.success).toBe(false)
  })

  it('accepts all 5 standard TYPE_NAMES values', () => {
    expect(TYPE_NAMES).toHaveLength(5)
    for (const name of TYPE_NAMES) {
      const r = createCourseTypeSchema.safeParse({ ...VALID, type_name: name })
      expect(r.success).toBe(true)
    }
  })
})
```

- [ ] **Step 2.2: Run test, verify FAIL**

Run: `cd frontend && npm test -- coursetype`
Expected: error — module `../coursetype` not found.

- [ ] **Step 2.3: Implement schema**

`frontend/src/schemas/coursetype.ts`:
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

- [ ] **Step 2.4: Run test, verify PASS**

Run: `cd frontend && npm test -- coursetype`
Expected: 6 tests pass.

- [ ] **Step 2.5: Typecheck + commit**

```bash
git add frontend/src/schemas/coursetype.ts frontend/src/schemas/__tests__/coursetype.test.ts
git commit -m "feat(curriculum): add CourseType zod schema with refinements"
```

---

## Task 3: Extend curriculum hooks

**File:** `frontend/src/lib/api/curriculum.ts`

- [ ] **Step 3.1: Append CourseType hooks**

Append to `frontend/src/lib/api/curriculum.ts` (after existing MasterCourse hooks):

```ts
import type { CourseType } from '@/types/coursetype'
import type { CreateCourseTypeInput, UpdateCourseTypeInput } from '@/schemas/coursetype'

const TYPES_BASE = '/api/v1/curriculum/types'
const COURSE_TYPES = (courseId: string) =>
  `/api/v1/curriculum/courses/${courseId}/types`

interface CourseTypeListResponse {
  data: CourseType[]
}

interface CourseTypeSingleResponse {
  data: CourseType
}

export function useCourseTypes(courseId: string | undefined) {
  return useQuery({
    queryKey: ['coursetypes', 'list', courseId],
    queryFn: () =>
      apiClient
        .get<CourseTypeListResponse>(COURSE_TYPES(courseId!))
        .then((r) => r.data.data),
    enabled: !!courseId,
  })
}

export function useCourseType(typeId: string | undefined) {
  return useQuery({
    queryKey: ['coursetypes', typeId],
    queryFn: () =>
      apiClient
        .get<CourseTypeSingleResponse>(`${TYPES_BASE}/${typeId}`)
        .then((r) => r.data.data),
    enabled: !!typeId,
  })
}

export function useCreateCourseType(courseId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCourseTypeInput) =>
      apiClient
        .post<CourseTypeSingleResponse>(COURSE_TYPES(courseId), input)
        .then((r) => r.data.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['coursetypes', 'list', courseId] }),
  })
}

export function useUpdateCourseType(typeId: string, courseId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateCourseTypeInput) =>
      apiClient
        .put<CourseTypeSingleResponse>(`${TYPES_BASE}/${typeId}`, input)
        .then((r) => r.data.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['coursetypes', 'list', courseId] })
      qc.invalidateQueries({ queryKey: ['coursetypes', typeId] })
    },
  })
}

export function useToggleCourseType(courseId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (typeId: string) =>
      apiClient.post(`${TYPES_BASE}/${typeId}/toggle`).then((r) => r.data),
    onSuccess: (_d, typeId) => {
      qc.invalidateQueries({ queryKey: ['coursetypes', 'list', courseId] })
      qc.invalidateQueries({ queryKey: ['coursetypes', typeId] })
    },
  })
}
```

- [ ] **Step 3.2: Typecheck + commit**

```
cd frontend && npm run typecheck
```
Expected: pass.

```bash
git add frontend/src/lib/api/curriculum.ts
git commit -m "feat(curriculum): add CourseType react-query hooks"
```

---

## Task 4: VariantCard

**File:** `frontend/src/portals/internal/components/curriculum/VariantCard.tsx`

- [ ] **Step 4.1: Implement card**

```tsx
import { Power } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import type { CourseType } from '@/types/coursetype'

interface Props {
  variant: CourseType
  selected: boolean
  onSelect: () => void
  onToggle: () => void
  canToggle: boolean
}

function fmtIDR(n: number) {
  return new Intl.NumberFormat('id-ID').format(n)
}

export default function VariantCard({ variant, selected, onSelect, onToggle, canToggle }: Props) {
  const isActive = variant.status === 'active'
  return (
    <button
      type="button"
      onClick={onSelect}
      className={cn(
        'w-full text-left p-3 rounded-lg border transition-colors',
        selected ? 'border-brand-600 bg-brand-50' : 'border-neutral-200 bg-white hover:border-neutral-300',
        !isActive && 'opacity-60',
      )}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex-1">
          <div className="font-medium text-sm text-neutral-900 truncate">{variant.type_name}</div>
          <div className="text-xs text-neutral-500 mt-0.5">
            Rp {fmtIDR(variant.normal_price)} (min Rp {fmtIDR(variant.min_price)})
          </div>
          <div className="text-xs text-neutral-500">
            {variant.min_participants}–{variant.max_participants} ppl
          </div>
        </div>
        {canToggle && (
          <button
            type="button"
            onClick={(e) => { e.stopPropagation(); onToggle() }}
            className={cn(
              'shrink-0 p-1.5 rounded-md transition-colors',
              isActive ? 'text-green-600 hover:bg-green-50' : 'text-neutral-400 hover:bg-neutral-100',
            )}
            aria-label={isActive ? 'Deactivate' : 'Activate'}
          >
            <Power className="w-4 h-4" />
          </button>
        )}
      </div>
    </button>
  )
}
```

- [ ] **Step 4.2: Typecheck + commit**

```
cd frontend && npm run typecheck
```

```bash
git add frontend/src/portals/internal/components/curriculum/VariantCard.tsx
git commit -m "feat(curriculum): add VariantCard component"
```

---

## Task 5: VariantForm

**File:** `frontend/src/portals/internal/components/curriculum/VariantForm.tsx`

- [ ] **Step 5.1: Implement form**

```tsx
import { useEffect } from 'react'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import MultiInput from '@/components/shared/MultiInput'
import Input from '@/components/ui/Input'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import {
  createCourseTypeSchema,
  TYPE_NAMES,
  PRICE_TYPES,
  CURRENCIES,
  type CreateCourseTypeInput,
} from '@/schemas/coursetype'
import { useCreateCourseType, useUpdateCourseType } from '@/lib/api/curriculum'
import type { CourseType } from '@/types/coursetype'

type Mode = { kind: 'create' } | { kind: 'edit'; variant: CourseType }

interface Props {
  courseId: string
  mode: Mode
  onSuccess: (variant: CourseType) => void
  onCancel: () => void
}

const DEFAULTS: CreateCourseTypeInput = {
  type_name: 'Reguler',
  price_type: 'one-time',
  price_currency: 'IDR',
  target_audience: '',
  certification_type: '',
  extra_docs: [],
  normal_price: 0,
  min_price: 0,
  min_participants: 1,
  max_participants: 1,
}

function variantToInput(v: CourseType): CreateCourseTypeInput {
  return {
    type_name: v.type_name,
    price_type: (PRICE_TYPES.includes(v.price_type as any) ? v.price_type : 'one-time') as CreateCourseTypeInput['price_type'],
    price_currency: 'IDR',
    target_audience: v.target_audience,
    certification_type: v.certification_type,
    extra_docs: v.extra_docs ?? [],
    normal_price: v.normal_price,
    min_price: v.min_price,
    min_participants: v.min_participants,
    max_participants: v.max_participants,
  }
}

export default function VariantForm({ courseId, mode, onSuccess, onCancel }: Props) {
  const create = useCreateCourseType(courseId)
  const update = useUpdateCourseType(mode.kind === 'edit' ? mode.variant.id : '', courseId)

  const {
    register, handleSubmit, control, reset,
    formState: { errors, isSubmitting },
  } = useForm<CreateCourseTypeInput>({
    resolver: zodResolver(createCourseTypeSchema),
    defaultValues: mode.kind === 'edit' ? variantToInput(mode.variant) : DEFAULTS,
  })

  useEffect(() => {
    if (mode.kind === 'edit') reset(variantToInput(mode.variant))
    else reset(DEFAULTS)
  }, [mode, reset])

  async function onSubmit(values: CreateCourseTypeInput) {
    try {
      const result = mode.kind === 'create'
        ? await create.mutateAsync(values)
        : await update.mutateAsync(values)
      toast.success(mode.kind === 'create' ? 'Variant created' : 'Variant updated')
      onSuccess(result)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to save variant')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="font-semibold text-neutral-900">
        {mode.kind === 'create' ? 'New Variant' : mode.variant.type_name}
      </h3>

      <FormField label="Type Name" required error={errors.type_name?.message}>
        <Select {...register('type_name')}>
          {TYPE_NAMES.map((n) => <option key={n} value={n}>{n}</option>)}
        </Select>
      </FormField>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Price Type" error={errors.price_type?.message}>
          <Select {...register('price_type')}>
            {PRICE_TYPES.map((p) => <option key={p} value={p}>{p}</option>)}
          </Select>
        </FormField>
        <FormField label="Currency" error={errors.price_currency?.message}>
          <Select {...register('price_currency')}>
            {CURRENCIES.map((c) => <option key={c} value={c}>{c}</option>)}
          </Select>
        </FormField>
      </div>

      <FormField label="Target Audience" error={errors.target_audience?.message}>
        <Input {...register('target_audience')} placeholder="e.g. Mahasiswa Tingkat Akhir" />
      </FormField>

      <FormField label="Certification Type" error={errors.certification_type?.message}>
        <Input {...register('certification_type')} placeholder="e.g. Certificate of Completion" />
      </FormField>

      <FormField label="Extra Docs">
        <Controller
          name="extra_docs"
          control={control}
          render={({ field }) => (
            <MultiInput value={field.value ?? []} onChange={field.onChange} placeholder="e.g. Course outline, Project brief" />
          )}
        />
      </FormField>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Normal Price (IDR)" required error={errors.normal_price?.message}>
          <Input
            type="number"
            min={0}
            {...register('normal_price', { valueAsNumber: true })}
          />
        </FormField>
        <FormField label="Min Price (IDR)" required error={errors.min_price?.message}>
          <Input
            type="number"
            min={0}
            {...register('min_price', { valueAsNumber: true })}
          />
        </FormField>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Min Participants" required error={errors.min_participants?.message}>
          <Input
            type="number"
            min={1}
            {...register('min_participants', { valueAsNumber: true })}
          />
        </FormField>
        <FormField label="Max Participants" required error={errors.max_participants?.message}>
          <Input
            type="number"
            min={1}
            {...register('max_participants', { valueAsNumber: true })}
          />
        </FormField>
      </div>

      <div className="flex gap-2 pt-2 border-t border-neutral-100">
        <Button type="button" variant="secondary" onClick={onCancel}>Cancel</Button>
        <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>Save</Button>
      </div>
    </form>
  )
}
```

- [ ] **Step 5.2: Typecheck + commit**

```
cd frontend && npm run typecheck
```

```bash
git add frontend/src/portals/internal/components/curriculum/VariantForm.tsx
git commit -m "feat(curriculum): add VariantForm component"
```

---

## Task 6: VariantsTab

**File:** `frontend/src/portals/internal/components/curriculum/VariantsTab.tsx`

- [ ] **Step 6.1: Implement tab container**

```tsx
import { useState } from 'react'
import { Plus } from 'lucide-react'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { useRBAC } from '@/lib/auth/useRBAC'
import { useCourseTypes, useToggleCourseType } from '@/lib/api/curriculum'
import VariantCard from './VariantCard'
import VariantForm from './VariantForm'
import type { CourseType } from '@/types/coursetype'

interface Props {
  courseId: string
}

type Selection = { kind: 'none' } | { kind: 'new' } | { kind: 'edit'; id: string }

export default function VariantsTab({ courseId }: Props) {
  const { canAccess } = useRBAC()
  const { data, isLoading } = useCourseTypes(courseId)
  const toggle = useToggleCourseType(courseId)
  const [selection, setSelection] = useState<Selection>({ kind: 'none' })

  const variants: CourseType[] = data ?? []
  const selected =
    selection.kind === 'edit'
      ? variants.find((v) => v.id === selection.id)
      : undefined

  function handleToggle(v: CourseType) {
    const willDeactivate = v.status === 'active'
    if (willDeactivate && !confirm("Toggle inactive? Won't appear in batch creation.")) return
    toggle.mutate(v.id)
  }

  if (isLoading) return <LoadingSpinner size="lg" />

  const canCreate = canAccess('create', 'coursetype')
  const canUpdate = canAccess('update', 'coursetype')

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Left: list */}
      <div className="lg:col-span-1 space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold text-neutral-700">
            Variants ({variants.length})
          </h2>
          <RoleGate action="create" resource="coursetype">
            <Button size="sm" onClick={() => setSelection({ kind: 'new' })}>
              <Plus className="w-4 h-4" /> Add
            </Button>
          </RoleGate>
        </div>

        {variants.length === 0 ? (
          <div className="text-sm text-neutral-500 p-4 border border-dashed border-neutral-200 rounded-lg text-center">
            No variants yet.
            {canCreate && ' Add the first variant to start.'}
          </div>
        ) : (
          <div className="space-y-2">
            {variants.map((v) => (
              <VariantCard
                key={v.id}
                variant={v}
                selected={selection.kind === 'edit' && selection.id === v.id}
                onSelect={() => setSelection({ kind: 'edit', id: v.id })}
                onToggle={() => handleToggle(v)}
                canToggle={canUpdate}
              />
            ))}
          </div>
        )}
      </div>

      {/* Right: form panel */}
      <div className="lg:col-span-2">
        {selection.kind === 'none' && (
          <div className="text-sm text-neutral-500 p-8 border border-dashed border-neutral-200 rounded-lg text-center">
            {variants.length === 0
              ? 'Click + Add to create the first variant.'
              : 'Select a variant to edit, or click + Add to create a new one.'}
          </div>
        )}

        {selection.kind === 'new' && canCreate && (
          <div className="bg-white border border-neutral-100 rounded-xl p-5">
            <VariantForm
              courseId={courseId}
              mode={{ kind: 'create' }}
              onSuccess={(v) => setSelection({ kind: 'edit', id: v.id })}
              onCancel={() => setSelection({ kind: 'none' })}
            />
          </div>
        )}

        {selection.kind === 'edit' && selected && (
          <div className="bg-white border border-neutral-100 rounded-xl p-5">
            <VariantForm
              courseId={courseId}
              mode={{ kind: 'edit', variant: selected }}
              onSuccess={(v) => setSelection({ kind: 'edit', id: v.id })}
              onCancel={() => setSelection({ kind: 'none' })}
            />
          </div>
        )}
      </div>
    </div>
  )
}
```

- [ ] **Step 6.2: Typecheck + commit**

```
cd frontend && npm run typecheck
```

```bash
git add frontend/src/portals/internal/components/curriculum/VariantsTab.tsx
git commit -m "feat(curriculum): add VariantsTab master-detail container"
```

---

## Task 7: Wire VariantsTab into CourseDetail

**File:** `frontend/src/portals/internal/pages/detail/CourseDetail.tsx`

- [ ] **Step 7.1: Update CourseDetail**

Find the line:
```tsx
import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { BookOpen, Edit } from 'lucide-react'
import DetailPageLayout, { type DetailTab, type BreadcrumbItem } from '@/components/layout/DetailPageLayout'
```

Add this import below those:
```tsx
import VariantsTab from '@/portals/internal/components/curriculum/VariantsTab'
```

Find the `handleTabChange` function:
```tsx
function handleTabChange(v: string) {
  if (v !== 'overview') return
  setTab(v)
}
```

Replace with:
```tsx
function handleTabChange(v: string) {
  if (v === 'overview' || v === 'variants') setTab(v)
  // versions/cert/settings remain disabled until iter 1C/1D/1E
}
```

Find the closing `</DetailPageLayout>` and look for the area where overview content is rendered (`{tab === 'overview' && (`). Just BEFORE `</DetailPageLayout>` (after the overview block ends), add:

```tsx
{tab === 'variants' && <VariantsTab courseId={id} />}
```

- [ ] **Step 7.2: Typecheck + tests**

```
cd frontend && npm run typecheck && npm test
```
Expected: typecheck pass; 14 + 6 = 20 tests pass.

- [ ] **Step 7.3: Commit**

```bash
git add frontend/src/portals/internal/pages/detail/CourseDetail.tsx
git commit -m "feat(curriculum): wire VariantsTab into CourseDetail"
```

---

## Task 8: Smoke Verify

- [ ] **Step 8.1: Run dev server**

```
cd frontend && npm run dev
```
Open http://localhost:5173.

- [ ] **Step 8.2: Manual smoke (8 skenario)**

Login `dept_leader`. Navigate to existing master course detail (`/internal/courses/:id`):

1. [ ] Click tab `Variants` → tab aktif (jadi tidak abu-abu lagi). List kosong → empty state "No variants yet. Add the first variant to start."
2. [ ] Click `+ Add` → form muncul kanan dgn default Reguler / one-time / IDR / 0 / 1 / 1
3. [ ] Submit `Reguler, normal=5000000, min=3000000, min_part=10, max_part=25` → toast "Variant created" → card muncul di list, selected
4. [ ] Tambah variant kedua (Privat, normal=8000000, min=6000000, min/max=1/3) → switch ke variant pertama dgn klik card → form prefilled dgn data variant pertama
5. [ ] Edit normal_price variant Reguler → save → toast "Variant updated" → card update
6. [ ] Click power icon di card → confirm dialog → konfirmasi → card opacity berubah, status inactive
7. [ ] Form: input min_price=10000000 + normal_price=5000000 → inline error "Min price harus ≤ Normal price"
8. [ ] Logout, login `facilitator` → tab Variants → tombol `+ Add` hidden, power icon hidden, form jika dipanggil readonly (klik card nampilkan form, save tetap muncul tapi user tidak bisa create)

> Step 8 catatan: facilitator masih bisa _melihat_ form karena UI tidak block render. Yg di-block hanya tombol Add dan toggle. Submit dari form akan ditolak backend (403). Acceptable untuk iter ini — full read-only mode form defer.

- [ ] **Step 8.3: Final verify**

```
cd frontend && npm run typecheck && npm test
```
Expected: typecheck clean, 20 tests pass.

Tidak ada commit di Task 8 kecuali ada bug yang ditemukan.

---

## Done Criteria

- [ ] Permission matrix: course_owner + course_creator dapat akses coursetype
- [ ] Types + zod schema + 6 tests
- [ ] 5 react-query hooks (list, get, create, update, toggle)
- [ ] 3 komponen baru (VariantCard, VariantForm, VariantsTab)
- [ ] CourseDetail Variants tab functional
- [ ] typecheck clean, vitest 20 tests pass
- [ ] 8 manual smoke pass
- [ ] All commits on `feat/curriculum-iter-1b`

Setelah merge → brainstorm Iter 1C (Versions / CourseVersion + CourseModule).
