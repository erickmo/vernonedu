# Curriculum Iter 1A — MasterCourse CRUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement MasterCourse CRUD pada portal internal — list/detail/create/edit/archive page hybrid dgn tab Overview aktif (tab lain disabled untuk iter berikutnya).

**Architecture:** React 18 + Vite + TS. Pakai pola Partner sebagai template. `StandardPageLayout` shell. React-query 5 untuk data. Permission via `RoleGate` + `canAccess`. Backend endpoint base: `/api/v1/curriculum/courses`. Pagination backend = `offset/limit`; UI tetap pakai page number (convert client-side).

**Tech Stack:** React Hook Form + zod, react-query 5, axios via `lib/api/client.ts`, lucide-react, tailwind, vitest.

**Spec:** `docs/superpowers/specs/2026-05-02-curriculum-iter-1a-mastercourse.md`.

---

## File Structure

| File | Action |
|---|---|
| `frontend/src/types/mastercourse.ts` | Create |
| `frontend/src/schemas/mastercourse.ts` | Create |
| `frontend/src/schemas/__tests__/mastercourse.test.ts` | Create |
| `frontend/src/lib/api/curriculum.ts` | Create |
| `frontend/src/components/shared/MultiInput.tsx` | Create |
| `frontend/src/components/shared/TabNav.tsx` | Create |
| `frontend/src/portals/internal/pages/Courses.tsx` | Replace |
| `frontend/src/portals/internal/pages/CourseCreatePage.tsx` | Create |
| `frontend/src/portals/internal/pages/CourseEditPage.tsx` | Create |
| `frontend/src/portals/internal/pages/detail/CourseDetail.tsx` | Replace |
| `frontend/src/portals/internal/components/CreateCourseModal.tsx` | Delete |
| `frontend/src/lib/api/catalog.ts` | Modify (add `@deprecated` JSDoc, no removal) |
| `frontend/src/App.tsx` | Modify (add 2 routes) |

---

## Task 1: Types & Schema (TDD)

**Files:**
- Create: `frontend/src/types/mastercourse.ts`
- Create: `frontend/src/schemas/mastercourse.ts`
- Test: `frontend/src/schemas/__tests__/mastercourse.test.ts`

- [ ] **Step 1.1: Create type file**

`frontend/src/types/mastercourse.ts`:
```ts
export type MasterCourseStatus = 'active' | 'archived'

export interface MasterCourse {
  id: string
  course_code: string
  course_name: string
  field: string
  core_competencies: string[]
  description: string
  supporting_app_url?: string
  status: MasterCourseStatus
  created_at: string
  updated_at: string
}

export interface MasterCourseFilters {
  search?: string
  field?: string
  status?: MasterCourseStatus
  department_id?: string
  page?: number
  limit?: number
}

export interface PaginatedMasterCourses {
  data: MasterCourse[]
  total: number
  offset: number
  limit: number
}
```

- [ ] **Step 1.2: Write failing schema test**

`frontend/src/schemas/__tests__/mastercourse.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { createMasterCourseSchema, FIELDS } from '../mastercourse'

describe('createMasterCourseSchema', () => {
  it('accepts minimal valid input', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'Web Development',
      field: 'Tech',
    })
    expect(r.success).toBe(true)
  })

  it('rejects empty course_code', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: '',
      course_name: 'X',
      field: 'Tech',
    })
    expect(r.success).toBe(false)
  })

  it('rejects empty course_name', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: '',
      field: 'Tech',
    })
    expect(r.success).toBe(false)
  })

  it('rejects unknown field', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'X',
      field: 'Magic',
    })
    expect(r.success).toBe(false)
  })

  it('accepts empty supporting_app_url', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'X',
      field: 'Tech',
      supporting_app_url: '',
    })
    expect(r.success).toBe(true)
  })

  it('accepts valid url', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'X',
      field: 'Tech',
      supporting_app_url: 'https://example.com',
    })
    expect(r.success).toBe(true)
  })

  it('rejects malformed url', () => {
    const r = createMasterCourseSchema.safeParse({
      course_code: 'MC-001',
      course_name: 'X',
      field: 'Tech',
      supporting_app_url: 'not-a-url',
    })
    expect(r.success).toBe(false)
  })

  it('exports FIELDS readonly tuple of 5', () => {
    expect(FIELDS).toHaveLength(5)
  })
})
```

- [ ] **Step 1.3: Run test — should FAIL**

Run: `cd frontend && npm test -- mastercourse`
Expected: FAIL — module `../mastercourse` not found.

- [ ] **Step 1.4: Implement schema**

`frontend/src/schemas/mastercourse.ts`:
```ts
import { z } from 'zod'

export const FIELDS = ['Tech', 'Business', 'Design', 'Education', 'Other'] as const
export type Field = typeof FIELDS[number]

export const createMasterCourseSchema = z.object({
  course_code: z.string().min(1, 'Code wajib').max(20),
  course_name: z.string().min(1, 'Name wajib').max(200),
  field: z.enum(FIELDS),
  core_competencies: z.array(z.string().min(1)).default([]),
  description: z.string().max(2000).default(''),
  supporting_app_url: z.union([z.string().url(), z.literal('')]).optional(),
})

export const updateMasterCourseSchema = createMasterCourseSchema.partial()

export type CreateMasterCourseInput = z.infer<typeof createMasterCourseSchema>
export type UpdateMasterCourseInput = z.infer<typeof updateMasterCourseSchema>
```

- [ ] **Step 1.5: Run test — should PASS**

Run: `cd frontend && npm test -- mastercourse`
Expected: 8 tests pass.

- [ ] **Step 1.6: Typecheck + commit**

Run: `cd frontend && npm run typecheck`
Expected: pass.

```bash
git add frontend/src/types/mastercourse.ts frontend/src/schemas/mastercourse.ts frontend/src/schemas/__tests__/mastercourse.test.ts
git commit -m "feat(curriculum): add MasterCourse types and zod schema"
```

---

## Task 2: API Hooks

**Files:**
- Create: `frontend/src/lib/api/curriculum.ts`

- [ ] **Step 2.1: Implement curriculum hooks**

`frontend/src/lib/api/curriculum.ts`:
```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'
import type {
  MasterCourse,
  MasterCourseFilters,
  PaginatedMasterCourses,
} from '@/types/mastercourse'
import type { CreateMasterCourseInput, UpdateMasterCourseInput } from '@/schemas/mastercourse'

const BASE = '/api/v1/curriculum/courses'

function toOffset(page: number | undefined, limit: number) {
  const p = Math.max(1, page ?? 1)
  return (p - 1) * limit
}

export function useMasterCourses(filters: MasterCourseFilters = {}) {
  const limit = filters.limit ?? 15
  const offset = toOffset(filters.page, limit)
  const params = {
    offset,
    limit,
    ...(filters.search ? { search: filters.search } : {}),
    ...(filters.field ? { field: filters.field } : {}),
    ...(filters.status ? { status: filters.status } : {}),
    ...(filters.department_id ? { department_id: filters.department_id } : {}),
  }
  return useQuery({
    queryKey: ['mastercourses', 'list', params],
    queryFn: () =>
      apiClient.get<PaginatedMasterCourses>(BASE, { params }).then((r) => r.data),
  })
}

export function useMasterCourse(id: string | undefined) {
  return useQuery({
    queryKey: ['mastercourses', id],
    queryFn: () => apiClient.get<MasterCourse>(`${BASE}/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreateMasterCourse() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateMasterCourseInput) =>
      apiClient.post<MasterCourse>(BASE, input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['mastercourses', 'list'] }),
  })
}

export function useUpdateMasterCourse(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: UpdateMasterCourseInput) =>
      apiClient.put<MasterCourse>(`${BASE}/${id}`, input).then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['mastercourses', 'list'] })
      qc.invalidateQueries({ queryKey: ['mastercourses', id] })
    },
  })
}

export function useArchiveMasterCourse() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`${BASE}/${id}/archive`).then((r) => r.data),
    onSuccess: (_d, id) => {
      qc.invalidateQueries({ queryKey: ['mastercourses', 'list'] })
      qc.invalidateQueries({ queryKey: ['mastercourses', id] })
    },
  })
}
```

- [ ] **Step 2.2: Typecheck + commit**

Run: `cd frontend && npm run typecheck`
Expected: pass.

```bash
git add frontend/src/lib/api/curriculum.ts
git commit -m "feat(curriculum): add MasterCourse react-query hooks"
```

---

## Task 3: MultiInput Component

**Files:**
- Create: `frontend/src/components/shared/MultiInput.tsx`

- [ ] **Step 3.1: Implement MultiInput**

`frontend/src/components/shared/MultiInput.tsx`:
```tsx
import { useState, KeyboardEvent } from 'react'
import { X } from 'lucide-react'
import Input from '@/components/ui/Input'

interface Props {
  value: string[]
  onChange: (next: string[]) => void
  placeholder?: string
  disabled?: boolean
}

export default function MultiInput({ value, onChange, placeholder, disabled }: Props) {
  const [draft, setDraft] = useState('')

  function addChip() {
    const trimmed = draft.trim()
    if (!trimmed) return
    if (value.includes(trimmed)) {
      setDraft('')
      return
    }
    onChange([...value, trimmed])
    setDraft('')
  }

  function removeChip(idx: number) {
    onChange(value.filter((_, i) => i !== idx))
  }

  function onKey(e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === 'Enter') {
      e.preventDefault()
      addChip()
    } else if (e.key === 'Backspace' && draft === '' && value.length > 0) {
      removeChip(value.length - 1)
    }
  }

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap gap-1.5">
        {value.map((chip, i) => (
          <span
            key={`${chip}-${i}`}
            className="inline-flex items-center gap-1 px-2 py-0.5 text-xs bg-neutral-100 text-neutral-700 rounded-full"
          >
            {chip}
            {!disabled && (
              <button
                type="button"
                onClick={() => removeChip(i)}
                className="hover:text-red-600"
                aria-label={`Remove ${chip}`}
              >
                <X className="w-3 h-3" />
              </button>
            )}
          </span>
        ))}
      </div>
      <Input
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={onKey}
        onBlur={addChip}
        placeholder={placeholder ?? 'Type and press Enter'}
        disabled={disabled}
      />
    </div>
  )
}
```

- [ ] **Step 3.2: Typecheck + commit**

Run: `cd frontend && npm run typecheck`
Expected: pass.

```bash
git add frontend/src/components/shared/MultiInput.tsx
git commit -m "feat(shared): add MultiInput component for chip input"
```

---

## Task 4: TabNav Component

**Files:**
- Create: `frontend/src/components/shared/TabNav.tsx`

- [ ] **Step 4.1: Implement TabNav**

`frontend/src/components/shared/TabNav.tsx`:
```tsx
import { cn } from '@/lib/utils/cn'

export interface Tab {
  key: string
  label: string
  disabled?: boolean
  disabledReason?: string
}

interface Props {
  tabs: Tab[]
  activeKey: string
  onChange: (key: string) => void
}

export default function TabNav({ tabs, activeKey, onChange }: Props) {
  return (
    <div className="border-b border-border" role="tablist">
      <div className="flex gap-1">
        {tabs.map((tab) => {
          const active = tab.key === activeKey
          return (
            <button
              key={tab.key}
              type="button"
              role="tab"
              aria-selected={active}
              disabled={tab.disabled}
              title={tab.disabled ? tab.disabledReason : undefined}
              onClick={() => !tab.disabled && onChange(tab.key)}
              className={cn(
                'px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
                active
                  ? 'border-primary text-primary'
                  : 'border-transparent text-neutral-600 hover:text-neutral-900',
                tab.disabled && 'opacity-40 cursor-not-allowed hover:text-neutral-600',
              )}
            >
              {tab.label}
            </button>
          )
        })}
      </div>
    </div>
  )
}
```

- [ ] **Step 4.2: Typecheck + commit**

Run: `cd frontend && npm run typecheck`
Expected: pass.

```bash
git add frontend/src/components/shared/TabNav.tsx
git commit -m "feat(shared): add TabNav component"
```

---

## Task 5: List Page (Courses.tsx)

**Files:**
- Replace: `frontend/src/portals/internal/pages/Courses.tsx`

- [ ] **Step 5.1: Implement Courses list page**

Overwrite `frontend/src/portals/internal/pages/Courses.tsx`:
```tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useMasterCourses } from '@/lib/api/curriculum'
import type { MasterCourse, MasterCourseStatus } from '@/types/mastercourse'
import { FIELDS } from '@/schemas/mastercourse'
import { Column } from '@/components/shared/DataTable'
import StatusBadge from '@/components/shared/StatusBadge'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 15

const COLUMNS: Column<MasterCourse>[] = [
  { header: 'Code', accessor: 'course_code', className: 'font-mono text-xs w-28' },
  { header: 'Name', accessor: 'course_name' },
  { header: 'Field', accessor: 'field', cell: (r) => <span className="capitalize">{r.field}</span> },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} />,
  },
]

export default function Courses() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [field, setField] = useState<string>('')
  const [status, setStatus] = useState<MasterCourseStatus | ''>('')

  const { data, isLoading } = useMasterCourses({
    page,
    limit: LIMIT,
    search: search || undefined,
    field: field || undefined,
    status: status || undefined,
  })

  return (
    <ListPageTemplate
      title="Courses"
      subtitle="Manage curriculum master courses"
      actions={
        <RoleGate action="create" resource="mastercourse">
          <Button onClick={() => navigate('/internal/courses/new')}>
            <Plus className="w-4 h-4" /> Add Course
          </Button>
        </RoleGate>
      }
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/courses/${r.id}`)}
      filters={
        <div className="flex gap-2 flex-wrap">
          <input
            type="search"
            placeholder="Search code or name"
            value={search}
            onChange={(e) => { setPage(1); setSearch(e.target.value) }}
            className="px-3 py-1.5 text-sm border border-border rounded-md min-w-[200px]"
          />
          <select
            value={field}
            onChange={(e) => { setPage(1); setField(e.target.value) }}
            className="px-3 py-1.5 text-sm border border-border rounded-md"
          >
            <option value="">All fields</option>
            {FIELDS.map((f) => <option key={f} value={f}>{f}</option>)}
          </select>
          <select
            value={status}
            onChange={(e) => { setPage(1); setStatus(e.target.value as MasterCourseStatus | '') }}
            className="px-3 py-1.5 text-sm border border-border rounded-md"
          >
            <option value="">All status</option>
            <option value="active">Active</option>
            <option value="archived">Archived</option>
          </select>
        </div>
      }
    />
  )
}
```

> **Note:** `ListPageTemplate` may not have a `filters` prop. Verify by reading `frontend/src/components/templates/ListPageTemplate.tsx`. If absent, add a `filters?: ReactNode` prop (rendered above the DataTable) — keep change minimal.

- [ ] **Step 5.2: Verify ListPageTemplate supports filters slot**

Run: `cd frontend && head -60 src/components/templates/ListPageTemplate.tsx`

If `filters` prop missing: edit `ListPageTemplate.tsx` to accept optional `filters?: ReactNode` and render above the DataTable wrapper:
```tsx
{filters && <div className="mb-3">{filters}</div>}
```

- [ ] **Step 5.3: Typecheck**

Run: `cd frontend && npm run typecheck`
Expected: pass.

> If `Course` type import in OTHER files breaks (e.g. detail page imports `Course`), Task 8 will replace those — for now, comment out the offending imports temporarily? **NO.** Don't bypass. Task 6/7/8 will replace consumers. If typecheck fails here because of `CourseDetail.tsx` referencing old `Course`, complete Task 8 first or stub the detail to a placeholder before committing this task.

Pragmatic order: do Task 5–8 as one atomic commit if needed. Steps 5.4–5.5 only commit if typecheck passes standalone.

- [ ] **Step 5.4: Commit (if typecheck passes)**

```bash
git add frontend/src/portals/internal/pages/Courses.tsx frontend/src/components/templates/ListPageTemplate.tsx
git commit -m "feat(curriculum): replace Courses list with MasterCourse hybrid"
```

If typecheck still fails (due to CourseDetail using old `Course`), **do NOT commit.** Continue to Task 8 first, then commit Tasks 5–8 together at end of Task 8.

---

## Task 6: Create Page

**Files:**
- Create: `frontend/src/portals/internal/pages/CourseCreatePage.tsx`

- [ ] **Step 6.1: Implement create page**

`frontend/src/portals/internal/pages/CourseCreatePage.tsx`:
```tsx
import { useNavigate } from 'react-router-dom'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import StandardPageLayout from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import MultiInput from '@/components/shared/MultiInput'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import { createMasterCourseSchema, FIELDS, type CreateMasterCourseInput } from '@/schemas/mastercourse'
import { useCreateMasterCourse } from '@/lib/api/curriculum'

export default function CourseCreatePage() {
  const navigate = useNavigate()
  const create = useCreateMasterCourse()

  const {
    register,
    handleSubmit,
    control,
    formState: { errors, isSubmitting },
  } = useForm<CreateMasterCourseInput>({
    resolver: zodResolver(createMasterCourseSchema),
    defaultValues: {
      course_code: '',
      course_name: '',
      field: 'Tech',
      core_competencies: [],
      description: '',
      supporting_app_url: '',
    },
  })

  async function onSubmit(values: CreateMasterCourseInput) {
    try {
      const created = await create.mutateAsync(values)
      toast.success('Course created')
      navigate(`/internal/courses/${created.id}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to create course')
    }
  }

  return (
    <StandardPageLayout
      title="Add Course"
      subtitle="Create a new master course"
      onBack={() => navigate('/internal/courses')}
    >
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 max-w-2xl">
        <FormField label="Course Code" required error={errors.course_code?.message}>
          <Input {...register('course_code')} placeholder="MC-001" />
        </FormField>

        <FormField label="Course Name" required error={errors.course_name?.message}>
          <Input {...register('course_name')} placeholder="Web Development" />
        </FormField>

        <FormField label="Field" required error={errors.field?.message}>
          <Select {...register('field')}>
            {FIELDS.map((f) => <option key={f} value={f}>{f}</option>)}
          </Select>
        </FormField>

        <FormField label="Core Competencies" error={errors.core_competencies?.message as string}>
          <Controller
            name="core_competencies"
            control={control}
            render={({ field }) => (
              <MultiInput value={field.value} onChange={field.onChange} placeholder="Type and press Enter" />
            )}
          />
        </FormField>

        <FormField label="Description" error={errors.description?.message}>
          <Textarea {...register('description')} rows={4} />
        </FormField>

        <FormField label="Supporting App URL" error={errors.supporting_app_url?.message}>
          <Input {...register('supporting_app_url')} placeholder="https://..." />
        </FormField>

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={() => navigate('/internal/courses')}>
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting}>
            {isSubmitting ? 'Saving...' : 'Save'}
          </Button>
        </div>
      </form>
    </StandardPageLayout>
  )
}
```

- [ ] **Step 6.2: Verify primitives signature**

Run: `cd frontend && head -20 src/components/ui/Input.tsx src/components/ui/Textarea.tsx src/components/ui/Select.tsx src/components/ui/Button.tsx src/components/layout/StandardPageLayout.tsx`

If `StandardPageLayout` has different prop names (e.g. `onBackClick` instead of `onBack`), adjust to match. If `Button` doesn't have `variant="secondary"`, replace with the actual variant name in use (check Partner pages for reference).

- [ ] **Step 6.3: Typecheck**

Run: `cd frontend && npm run typecheck`
Expected: pass (assuming Tasks 5/8 land together — see Task 5 note).

---

## Task 7: Edit Page

**Files:**
- Create: `frontend/src/portals/internal/pages/CourseEditPage.tsx`

- [ ] **Step 7.1: Implement edit page**

`frontend/src/portals/internal/pages/CourseEditPage.tsx`:
```tsx
import { useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import StandardPageLayout from '@/components/layout/StandardPageLayout'
import FormField from '@/components/shared/FormField'
import MultiInput from '@/components/shared/MultiInput'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import RoleGate from '@/components/shared/RoleGate'
import { updateMasterCourseSchema, FIELDS, type UpdateMasterCourseInput } from '@/schemas/mastercourse'
import { useMasterCourse, useUpdateMasterCourse, useArchiveMasterCourse } from '@/lib/api/curriculum'

export default function CourseEditPage() {
  const navigate = useNavigate()
  const { id = '' } = useParams<{ id: string }>()
  const { data, isLoading } = useMasterCourse(id)
  const update = useUpdateMasterCourse(id)
  const archive = useArchiveMasterCourse()

  const {
    register, handleSubmit, control, reset,
    formState: { errors, isSubmitting },
  } = useForm<UpdateMasterCourseInput>({
    resolver: zodResolver(updateMasterCourseSchema),
  })

  useEffect(() => {
    if (data) {
      reset({
        course_code: data.course_code,
        course_name: data.course_name,
        field: data.field as any,
        core_competencies: data.core_competencies ?? [],
        description: data.description,
        supporting_app_url: data.supporting_app_url ?? '',
      })
    }
  }, [data, reset])

  async function onSubmit(values: UpdateMasterCourseInput) {
    try {
      await update.mutateAsync(values)
      toast.success('Course updated')
      navigate(`/internal/courses/${id}`)
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update course')
    }
  }

  async function onArchive() {
    if (!confirm('Archive this course? It will be hidden from active list.')) return
    try {
      await archive.mutateAsync(id)
      toast.success('Course archived')
      navigate('/internal/courses')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to archive')
    }
  }

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  return (
    <StandardPageLayout
      title="Edit Course"
      subtitle={data.course_code}
      onBack={() => navigate(`/internal/courses/${id}`)}
    >
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 max-w-2xl">
        <FormField label="Course Code" required error={errors.course_code?.message}>
          <Input {...register('course_code')} />
        </FormField>
        <FormField label="Course Name" required error={errors.course_name?.message}>
          <Input {...register('course_name')} />
        </FormField>
        <FormField label="Field" required error={errors.field?.message}>
          <Select {...register('field')}>
            {FIELDS.map((f) => <option key={f} value={f}>{f}</option>)}
          </Select>
        </FormField>
        <FormField label="Core Competencies">
          <Controller
            name="core_competencies"
            control={control}
            render={({ field }) => (
              <MultiInput value={field.value ?? []} onChange={field.onChange} />
            )}
          />
        </FormField>
        <FormField label="Description" error={errors.description?.message}>
          <Textarea {...register('description')} rows={4} />
        </FormField>
        <FormField label="Supporting App URL" error={errors.supporting_app_url?.message}>
          <Input {...register('supporting_app_url')} />
        </FormField>

        <div className="flex gap-2 pt-2 border-t border-border">
          <Button type="button" variant="secondary" onClick={() => navigate(`/internal/courses/${id}`)}>
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting}>
            {isSubmitting ? 'Saving...' : 'Save'}
          </Button>
          {data.status === 'active' && (
            <RoleGate action="delete" resource="mastercourse">
              <Button type="button" variant="danger" onClick={onArchive}>
                Archive
              </Button>
            </RoleGate>
          )}
        </div>
      </form>
    </StandardPageLayout>
  )
}
```

- [ ] **Step 7.2: Typecheck (defer commit until Task 8)**

Run: `cd frontend && npm run typecheck`

---

## Task 8: Detail Page (Replace)

**Files:**
- Replace: `frontend/src/portals/internal/pages/detail/CourseDetail.tsx`

- [ ] **Step 8.1: Implement detail with tabs**

Overwrite `frontend/src/portals/internal/pages/detail/CourseDetail.tsx`:
```tsx
import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Edit } from 'lucide-react'
import { useMasterCourse } from '@/lib/api/curriculum'
import DetailPageLayout from '@/components/layout/DetailPageLayout'
import TabNav, { type Tab } from '@/components/shared/TabNav'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const TABS: Tab[] = [
  { key: 'overview', label: 'Overview' },
  { key: 'variants', label: 'Variants', disabled: true, disabledReason: 'Coming in Iter 1B' },
  { key: 'versions', label: 'Versions', disabled: true, disabledReason: 'Coming in Iter 1C' },
  { key: 'cert', label: 'Certificate', disabled: true, disabledReason: 'Coming in Iter 1D' },
  { key: 'settings', label: 'Settings', disabled: true, disabledReason: 'Coming in Iter 1E' },
]

export default function CourseDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useMasterCourse(id)
  const [tab, setTab] = useState('overview')

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  return (
    <DetailPageLayout
      title={`${data.course_code} · ${data.course_name}`}
      subtitle={
        <span className="flex items-center gap-2 text-sm text-neutral-600">
          Field: <span className="font-medium">{data.field}</span>
          <span>·</span>
          <StatusBadge status={data.status} />
        </span>
      }
      onBack={() => navigate('/internal/courses')}
      actions={
        <RoleGate action="update" resource="mastercourse">
          <Button onClick={() => navigate(`/internal/courses/${id}/edit`)}>
            <Edit className="w-4 h-4" /> Edit
          </Button>
        </RoleGate>
      }
    >
      <TabNav tabs={TABS} activeKey={tab} onChange={setTab} />

      {tab === 'overview' && (
        <div className="space-y-4 mt-6">
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Description</h3>
            <p className="text-sm text-neutral-700 whitespace-pre-wrap">
              {data.description || '—'}
            </p>
          </section>

          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Core Competencies</h3>
            {data.core_competencies.length === 0 ? (
              <p className="text-sm text-neutral-400">—</p>
            ) : (
              <div className="flex flex-wrap gap-1.5">
                {data.core_competencies.map((c, i) => (
                  <span key={`${c}-${i}`} className="px-2 py-0.5 text-xs bg-neutral-100 text-neutral-700 rounded-full">
                    {c}
                  </span>
                ))}
              </div>
            )}
          </section>

          {data.supporting_app_url && (
            <section>
              <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Supporting App</h3>
              <a
                href={data.supporting_app_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-primary hover:underline"
              >
                {data.supporting_app_url}
              </a>
            </section>
          )}

          <section className="pt-4 border-t border-border text-xs text-neutral-500">
            Created: {new Date(data.created_at).toLocaleDateString()} ·
            Updated: {new Date(data.updated_at).toLocaleDateString()}
          </section>
        </div>
      )}
    </DetailPageLayout>
  )
}
```

- [ ] **Step 8.2: Verify DetailPageLayout signature**

Run: `cd frontend && head -40 src/components/layout/DetailPageLayout.tsx`

Adjust prop names (`actions`, `onBack`, `subtitle`) to match actual signature. If `subtitle` accepts only `string`, change to `string` and inline status differently.

- [ ] **Step 8.3: Typecheck**

Run: `cd frontend && npm run typecheck`
Expected: pass.

- [ ] **Step 8.4: Combined commit for Tasks 5–8**

```bash
git add frontend/src/portals/internal/pages/Courses.tsx \
        frontend/src/portals/internal/pages/CourseCreatePage.tsx \
        frontend/src/portals/internal/pages/CourseEditPage.tsx \
        frontend/src/portals/internal/pages/detail/CourseDetail.tsx \
        frontend/src/components/templates/ListPageTemplate.tsx
git commit -m "feat(curriculum): MasterCourse list/detail/create/edit pages with tabs"
```

---

## Task 9: Routes Registration

**Files:**
- Modify: `frontend/src/App.tsx`

- [ ] **Step 9.1: Add routes**

In `frontend/src/App.tsx`:

1. Add imports near other internal page imports:
```tsx
import CourseCreatePage from '@/portals/internal/pages/CourseCreatePage'
import CourseEditPage from '@/portals/internal/pages/CourseEditPage'
```

2. In the `/internal` route block, REPLACE the existing courses routes. Find the line:
```tsx
<Route path="courses" element={<Courses />} />
```
and the existing detail line:
```tsx
<Route path="courses/:id" element={<CourseDetail />} />
```

Replace those with (in this exact order — `/new` and `/edit` BEFORE `/:id`):
```tsx
<Route path="courses" element={<Courses />} />
<Route path="courses/new" element={<CourseCreatePage />} />
<Route path="courses/:id/edit" element={<CourseEditPage />} />
<Route path="courses/:id" element={<CourseDetail />} />
```

- [ ] **Step 9.2: Typecheck**

Run: `cd frontend && npm run typecheck`
Expected: pass.

- [ ] **Step 9.3: Commit**

```bash
git add frontend/src/App.tsx
git commit -m "feat(curriculum): register MasterCourse create/edit routes"
```

---

## Task 10: Cleanup CreateCourseModal + Deprecate flat Course

**Files:**
- Delete: `frontend/src/portals/internal/components/CreateCourseModal.tsx`
- Modify: `frontend/src/lib/api/catalog.ts` (add deprecation JSDoc, no removal)

- [ ] **Step 10.1: Find any reference to CreateCourseModal**

Run: `cd frontend && grep -rn "CreateCourseModal" src --include="*.tsx" --include="*.ts"`

Should be only the file itself (Courses.tsx no longer references it after Task 5). If any other reference found, remove it.

- [ ] **Step 10.2: Delete file**

Run: `cd /Users/erickmo/Desktop/Project/vernonedu2 && rm frontend/src/portals/internal/components/CreateCourseModal.tsx`

- [ ] **Step 10.3: Add deprecation JSDoc to catalog.ts**

In `frontend/src/lib/api/catalog.ts`, find the `Course` interface and add a JSDoc comment ABOVE it:
```ts
/**
 * @deprecated For admin views, use `MasterCourse` from `@/types/mastercourse` and hooks from `@/lib/api/curriculum`.
 * Retained for student catalog (composite view) until Iter 1B.
 */
export interface Course {
```

Also add JSDoc above `useCourses`:
```ts
/** @deprecated Use `useMasterCourses` from `@/lib/api/curriculum` for admin views. */
export function useCourses(filters: CourseFilters = {}) {
```

And above `useCourse`:
```ts
/** @deprecated Use `useMasterCourse` from `@/lib/api/curriculum` for admin views. */
export function useCourse(id: string) {
```

- [ ] **Step 10.4: Typecheck**

Run: `cd frontend && npm run typecheck`
Expected: pass.

- [ ] **Step 10.5: Commit**

```bash
git add frontend/src/portals/internal/components/CreateCourseModal.tsx frontend/src/lib/api/catalog.ts
git commit -m "chore(curriculum): remove CreateCourseModal, deprecate flat Course hooks"
```

---

## Task 11: Final Smoke + Verify

- [ ] **Step 11.1: Full typecheck + tests**

Run:
```bash
cd frontend
npm run typecheck
npm test
```
Expected: typecheck pass, 14+ tests pass (8 mastercourse schema + 6 permissions).

- [ ] **Step 11.2: Run dev server**

Run: `cd frontend && npm run dev`
Open http://localhost:5173 (or shown port).

- [ ] **Step 11.3: Manual smoke checklist (record results)**

Login as `dept_leader` (or your test user with create permission). Walk through:

1. [ ] Navigate `/internal/courses` → list muncul (atau empty state)
2. [ ] Click "Add Course" → form muncul
3. [ ] Submit form code=MC-TEST, name=Test Course, field=Tech → toast success → redirect ke detail
4. [ ] Detail tampil dgn data benar; tabs Variants/Versions/Cert/Settings disabled dgn tooltip
5. [ ] Click "Edit" → form prefilled → ubah name → save → redirect detail dgn name baru
6. [ ] Click "Edit" → click "Archive" → confirm → toast → redirect list, course tidak muncul di filter Active
7. [ ] Filter status=Archived → archived course muncul
8. [ ] Login as `facilitator` → akses `/internal/courses` → tombol "Add Course" hidden
9. [ ] Login as `student` → akses `/internal/courses` → 403 atau redirect ke `/student`

Document hasil di PR description.

- [ ] **Step 11.4: Verify student catalog tidak regressi**

Login as `student` → `/student/catalog` → list course tampil normal seperti sebelum (pakai flat `Course` hook lama, tidak diubah).

- [ ] **Step 11.5: Final commit (jika ada perubahan)**

Kalau Step 11.3 reveals minor bugs, fix them dgn commit terpisah `fix(curriculum): ...`.

---

## Done Criteria

- [ ] 8 task selesai (1: types/schema, 2: hooks, 3: MultiInput, 4: TabNav, 5–8: pages, 9: routes, 10: cleanup, 11: smoke)
- [ ] vitest 14+ tests pass
- [ ] typecheck pass
- [ ] 9 manual smoke skenario (Step 11.3 + 11.4) pass
- [ ] CreateCourseModal lama dihapus
- [ ] Student catalog tidak regressi
- [ ] All commits di branch `feat/curriculum-iter-1a` (atau equivalent)

Setelah merge → brainstorm Iter 1B (Variants / CourseType).
