# Curriculum Iter 1D — CourseModule Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans.

**Goal:** CRUD CourseModule inline di `VersionDetailPanel` dgn DnD reorder + lock saat version approved/archived.

**Architecture:** React-Query hooks extend `lib/api/curriculum.ts`. 4 new components di `portals/internal/components/curriculum/`. `@dnd-kit` untuk drag-drop. Optimistic local reorder + diff-based PUT serial. Lock UI based on `version.status`.

**Tech Stack:** React 18 + Vite + TS, RHF + zod, react-query 5, vitest, **@dnd-kit/core + @dnd-kit/sortable + @dnd-kit/utilities**.

**Spec:** `docs/superpowers/specs/2026-05-02-curriculum-iter-1d-coursemodule.md`.

---

## File Structure

| File | Action |
|---|---|
| `frontend/package.json` | Modify (add @dnd-kit deps) |
| `frontend/src/types/coursemodule.ts` | Create |
| `frontend/src/schemas/coursemodule.ts` | Create |
| `frontend/src/schemas/__tests__/coursemodule.test.ts` | Create |
| `frontend/src/lib/api/curriculum.ts` | Modify (extend) |
| `frontend/src/portals/internal/components/curriculum/ModuleRow.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/ModuleList.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/ModuleForm.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/ModulesSection.tsx` | Create |
| `frontend/src/portals/internal/components/curriculum/VersionDetailPanel.tsx` | Modify (render ModulesSection) |

---

## Task 0: Install @dnd-kit

- [ ] **Step 0.1: Install deps**

```bash
cd frontend && npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities --save
```

- [ ] **Step 0.2: Commit lock + package**

```bash
git add frontend/package.json frontend/package-lock.json
git commit -m "chore(frontend): add @dnd-kit deps for module reorder"
```

---

## Task 1: Type

- [ ] **Step 1.1: Create**

`frontend/src/types/coursemodule.ts`:
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

- [ ] **Step 1.2: Typecheck + commit**
```bash
cd frontend && npm run typecheck
git add frontend/src/types/coursemodule.ts
git commit -m "feat(curriculum): add CourseModule type"
```

---

## Task 2: Schema (TDD)

- [ ] **Step 2.1: Test**

`frontend/src/schemas/__tests__/coursemodule.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { createCourseModuleSchema, updateCourseModuleSchema } from '../coursemodule'

const VALID = {
  module_code: 'CODE-001',
  module_title: 'Pemrograman Dasar',
  duration_hours: 8,
  sequence: 1,
  content_depth: '',
  topics: [],
  practical_activities: [],
  assessment_method: '',
  tools_required: [],
  requirements: [],
  is_reference: false,
}

describe('createCourseModuleSchema', () => {
  it('accepts valid input', () => {
    expect(createCourseModuleSchema.safeParse(VALID).success).toBe(true)
  })
  it('rejects empty module_code', () => {
    expect(createCourseModuleSchema.safeParse({ ...VALID, module_code: '' }).success).toBe(false)
  })
  it('rejects empty module_title', () => {
    expect(createCourseModuleSchema.safeParse({ ...VALID, module_title: '' }).success).toBe(false)
  })
  it('rejects sequence <= 0', () => {
    expect(createCourseModuleSchema.safeParse({ ...VALID, sequence: 0 }).success).toBe(false)
  })
  it('rejects negative duration_hours', () => {
    expect(createCourseModuleSchema.safeParse({ ...VALID, duration_hours: -1 }).success).toBe(false)
  })
  it('accepts arrays + populates topics/tools/requirements', () => {
    const r = createCourseModuleSchema.safeParse({
      ...VALID,
      topics: ['Variables', 'Loops'],
      tools_required: ['VS Code'],
      requirements: ['Laptop'],
    })
    expect(r.success).toBe(true)
  })
})

describe('updateCourseModuleSchema', () => {
  it('does not include module_code', () => {
    const keys = Object.keys(updateCourseModuleSchema.shape ?? {})
    expect(keys).not.toContain('module_code')
    expect(keys).not.toContain('is_reference')
  })
})
```

- [ ] **Step 2.2: Run test FAIL**
```
cd frontend && npm test -- coursemodule
```

- [ ] **Step 2.3: Implement**

`frontend/src/schemas/coursemodule.ts`:
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

export const updateCourseModuleSchema = createCourseModuleSchema.omit({
  module_code: true,
  is_reference: true,
})

export type CreateCourseModuleInput = z.infer<typeof createCourseModuleSchema>
export type UpdateCourseModuleInput = z.infer<typeof updateCourseModuleSchema>
```

- [ ] **Step 2.4: Run test PASS**
```
cd frontend && npm test -- coursemodule
```

- [ ] **Step 2.5: Commit**
```bash
git add frontend/src/schemas/coursemodule.ts frontend/src/schemas/__tests__/coursemodule.test.ts
git commit -m "feat(curriculum): add CourseModule zod schema"
```

---

## Task 3: Hooks

- [ ] **Step 3.1: Append CourseModule hooks ke `lib/api/curriculum.ts`**

```ts
import type { CourseModule } from '@/types/coursemodule'
import type {
  CreateCourseModuleInput,
  UpdateCourseModuleInput,
} from '@/schemas/coursemodule'

const MODULES_BASE = '/api/v1/curriculum/modules'
const VERSION_MODULES = (versionId: string) =>
  `/api/v1/curriculum/versions/${versionId}/modules`

interface CourseModuleListResponse { data: CourseModule[] }
interface CourseModuleSingleResponse { data: CourseModule }

export function useCourseModules(versionId: string | undefined) {
  return useQuery({
    queryKey: ['coursemodules', 'list', versionId],
    queryFn: () =>
      apiClient.get<CourseModuleListResponse>(VERSION_MODULES(versionId!))
        .then((r) => r.data.data),
    enabled: !!versionId,
  })
}

export function useCourseModule(moduleId: string | undefined) {
  return useQuery({
    queryKey: ['coursemodules', moduleId],
    queryFn: () =>
      apiClient.get<CourseModuleSingleResponse>(`${MODULES_BASE}/${moduleId}`)
        .then((r) => r.data.data),
    enabled: !!moduleId,
  })
}

export function useCreateCourseModule(versionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateCourseModuleInput) =>
      apiClient.post(VERSION_MODULES(versionId), input).then((r) => r.data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['coursemodules', 'list', versionId] }),
  })
}

export function useUpdateCourseModule(versionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (args: { moduleId: string; input: UpdateCourseModuleInput }) =>
      apiClient.put(`${MODULES_BASE}/${args.moduleId}`, args.input).then((r) => r.data),
    onSuccess: (_d, { moduleId }) => {
      qc.invalidateQueries({ queryKey: ['coursemodules', 'list', versionId] })
      qc.invalidateQueries({ queryKey: ['coursemodules', moduleId] })
    },
  })
}

export function useDeleteCourseModule(versionId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (moduleId: string) =>
      apiClient.delete(`${MODULES_BASE}/${moduleId}`).then((r) => r.data),
    onSuccess: () =>
      qc.invalidateQueries({ queryKey: ['coursemodules', 'list', versionId] }),
  })
}
```

- [ ] **Step 3.2: Typecheck + commit**
```
cd frontend && npm run typecheck
git add frontend/src/lib/api/curriculum.ts
git commit -m "feat(curriculum): add CourseModule react-query hooks"
```

---

## Task 4: ModuleRow

- [ ] **Step 4.1: Implement sortable row**

`frontend/src/portals/internal/components/curriculum/ModuleRow.tsx`:
```tsx
import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { GripVertical, Pencil, Trash2 } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import type { CourseModule } from '@/types/coursemodule'

interface Props {
  module: CourseModule
  locked: boolean
  onEdit: () => void
  onDelete: () => void
}

export default function ModuleRow({ module: m, locked, onEdit, onDelete }: Props) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: m.id,
    disabled: locked,
  })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={cn(
        'grid grid-cols-[24px_40px_120px_1fr_80px_60px_80px] items-center gap-3 px-3 py-2 border-b border-neutral-100 bg-white',
        isDragging && 'shadow-md',
      )}
    >
      {!locked ? (
        <button
          type="button"
          {...attributes}
          {...listeners}
          className="cursor-grab text-neutral-400 hover:text-neutral-600"
          aria-label="Drag to reorder"
        >
          <GripVertical className="w-4 h-4" />
        </button>
      ) : <span />}

      <div className="text-sm text-neutral-500">{m.sequence}</div>
      <div className="text-sm font-mono text-neutral-700 truncate">{m.module_code}</div>
      <div className="text-sm text-neutral-900 truncate">{m.module_title}</div>
      <div className="text-xs text-neutral-500">{m.duration_hours} jam</div>
      <div className="text-xs text-neutral-500">{m.tools_required.length}</div>
      <div className="flex items-center gap-1 justify-end">
        {!locked && (
          <>
            <button onClick={onEdit} className="p-1 text-neutral-500 hover:text-brand-600" aria-label="Edit">
              <Pencil className="w-4 h-4" />
            </button>
            <button onClick={onDelete} className="p-1 text-neutral-500 hover:text-red-600" aria-label="Delete">
              <Trash2 className="w-4 h-4" />
            </button>
          </>
        )}
      </div>
    </div>
  )
}
```

- [ ] **Step 4.2: Typecheck + commit**

---

## Task 5: ModuleList

- [ ] **Step 5.1: Implement DnD list**

`frontend/src/portals/internal/components/curriculum/ModuleList.tsx`:
```tsx
import { useEffect, useState } from 'react'
import { toast } from 'sonner'
import {
  DndContext, closestCenter, KeyboardSensor, PointerSensor,
  useSensor, useSensors, DragEndEvent,
} from '@dnd-kit/core'
import {
  arrayMove, SortableContext, sortableKeyboardCoordinates,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  useCourseModules, useUpdateCourseModule, useDeleteCourseModule,
} from '@/lib/api/curriculum'
import ModuleRow from './ModuleRow'
import type { CourseModule } from '@/types/coursemodule'

interface Props {
  versionId: string
  locked: boolean
  onEdit: (m: CourseModule) => void
}

function moduleToUpdateInput(m: CourseModule, sequence: number) {
  return {
    module_title: m.module_title,
    duration_hours: m.duration_hours,
    sequence,
    content_depth: m.content_depth,
    topics: m.topics,
    practical_activities: m.practical_activities,
    assessment_method: m.assessment_method,
    tools_required: m.tools_required,
    requirements: m.requirements,
  }
}

export default function ModuleList({ versionId, locked, onEdit }: Props) {
  const { data, isLoading } = useCourseModules(versionId)
  const update = useUpdateCourseModule(versionId)
  const del = useDeleteCourseModule(versionId)

  const [items, setItems] = useState<CourseModule[]>([])
  const [pendingDelete, setPendingDelete] = useState<CourseModule | null>(null)

  useEffect(() => {
    setItems((data ?? []).slice().sort((a, b) => a.sequence - b.sequence))
  }, [data])

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 4 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  )

  async function handleDragEnd(e: DragEndEvent) {
    const { active, over } = e
    if (!over || active.id === over.id) return

    const oldIndex = items.findIndex((m) => m.id === active.id)
    const newIndex = items.findIndex((m) => m.id === over.id)
    const reordered = arrayMove(items, oldIndex, newIndex)
    setItems(reordered)

    const changed = reordered
      .map((m, idx) => ({ m, newSeq: idx + 1 }))
      .filter(({ m, newSeq }) => m.sequence !== newSeq)

    try {
      for (const { m, newSeq } of changed) {
        await update.mutateAsync({
          moduleId: m.id,
          input: moduleToUpdateInput(m, newSeq),
        })
      }
      toast.success('Module order saved')
    } catch (err: any) {
      toast.error(err?.response?.data?.message ?? 'Failed to save order')
      setItems((data ?? []).slice().sort((a, b) => a.sequence - b.sequence))
    }
  }

  if (isLoading) return <LoadingSpinner size="md" />

  if (items.length === 0) {
    return (
      <div className="text-sm text-neutral-500 p-6 border border-dashed border-neutral-200 rounded-lg text-center">
        No modules yet. Click + Add Module to start.
      </div>
    )
  }

  return (
    <>
      <div className="border border-neutral-200 rounded-lg overflow-hidden">
        <div className="grid grid-cols-[24px_40px_120px_1fr_80px_60px_80px] items-center gap-3 px-3 py-2 border-b border-neutral-200 bg-neutral-50 text-xs font-medium uppercase tracking-wide text-neutral-500">
          <span />
          <span>#</span>
          <span>Code</span>
          <span>Title</span>
          <span>Duration</span>
          <span>Tools</span>
          <span className="text-right">Actions</span>
        </div>
        <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
          <SortableContext items={items.map((m) => m.id)} strategy={verticalListSortingStrategy}>
            {items.map((m) => (
              <ModuleRow
                key={m.id}
                module={m}
                locked={locked}
                onEdit={() => onEdit(m)}
                onDelete={() => setPendingDelete(m)}
              />
            ))}
          </SortableContext>
        </DndContext>
      </div>

      <ConfirmDialog
        open={!!pendingDelete}
        title="Delete module?"
        message={`Delete "${pendingDelete?.module_title}"? This cannot be undone.`}
        onConfirm={async () => {
          if (!pendingDelete) return
          try {
            await del.mutateAsync(pendingDelete.id)
            toast.success('Module deleted')
          } catch (err: any) {
            toast.error(err?.response?.data?.message ?? 'Failed to delete')
          } finally {
            setPendingDelete(null)
          }
        }}
        onCancel={() => setPendingDelete(null)}
      />
    </>
  )
}
```

> **Note:** Verify `ConfirmDialog` API. Adjust props if signature differs.

- [ ] **Step 5.2: Verify ConfirmDialog**

```bash
grep -n "export\|interface\|Props" /Users/erickmo/Desktop/Project/vernonedu2/frontend/src/components/shared/ConfirmDialog.tsx | head -10
```

Adjust `onConfirm`/`onCancel` props or pass alternatives matching actual signature.

- [ ] **Step 5.3: Typecheck + commit**

---

## Task 6: ModuleForm

- [ ] **Step 6.1: Implement form (drawer/modal)**

`frontend/src/portals/internal/components/curriculum/ModuleForm.tsx`:
```tsx
import { useEffect } from 'react'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import FormField from '@/components/shared/FormField'
import MultiInput from '@/components/shared/MultiInput'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import {
  createCourseModuleSchema,
  updateCourseModuleSchema,
  type CreateCourseModuleInput,
  type UpdateCourseModuleInput,
} from '@/schemas/coursemodule'
import { useCreateCourseModule, useUpdateCourseModule } from '@/lib/api/curriculum'
import type { CourseModule } from '@/types/coursemodule'

type Mode = { kind: 'create'; defaultSequence: number } | { kind: 'edit'; module: CourseModule }

interface Props {
  versionId: string
  mode: Mode
  onSuccess: () => void
  onCancel: () => void
}

const EMPTY_CREATE: CreateCourseModuleInput = {
  module_code: '',
  module_title: '',
  duration_hours: 0,
  sequence: 1,
  content_depth: '',
  topics: [],
  practical_activities: [],
  assessment_method: '',
  tools_required: [],
  requirements: [],
  is_reference: false,
}

function moduleToUpdate(m: CourseModule): UpdateCourseModuleInput {
  return {
    module_title: m.module_title,
    duration_hours: m.duration_hours,
    sequence: m.sequence,
    content_depth: m.content_depth,
    topics: m.topics,
    practical_activities: m.practical_activities,
    assessment_method: m.assessment_method,
    tools_required: m.tools_required,
    requirements: m.requirements,
  }
}

export default function ModuleForm({ versionId, mode, onSuccess, onCancel }: Props) {
  const create = useCreateCourseModule(versionId)
  const update = useUpdateCourseModule(versionId)
  const isEdit = mode.kind === 'edit'

  const { register, handleSubmit, control, reset, setError, formState: { errors, isSubmitting } } =
    useForm<any>({
      resolver: zodResolver(isEdit ? updateCourseModuleSchema : createCourseModuleSchema),
      defaultValues: isEdit
        ? moduleToUpdate(mode.module)
        : { ...EMPTY_CREATE, sequence: mode.defaultSequence },
    })

  useEffect(() => {
    if (isEdit) reset(moduleToUpdate(mode.module))
    else reset({ ...EMPTY_CREATE, sequence: (mode as any).defaultSequence })
  }, [mode, reset, isEdit])

  async function onSubmit(values: any) {
    try {
      if (isEdit) {
        await update.mutateAsync({ moduleId: mode.module.id, input: values })
        toast.success('Module updated')
      } else {
        await create.mutateAsync(values)
        toast.success('Module created')
      }
      onSuccess()
    } catch (e: any) {
      const msg = e?.response?.data?.message ?? 'Failed to save module'
      if (!isEdit && /code|duplicate|exists/i.test(msg)) {
        setError('module_code', { message: msg })
      }
      toast.error(msg)
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <h3 className="font-semibold text-neutral-900">
        {isEdit ? 'Edit Module' : 'New Module'}
      </h3>

      {!isEdit && (
        <FormField label="Module Code" required error={errors.module_code?.message as string}>
          <Input {...register('module_code')} placeholder="e.g. CODE-001" />
        </FormField>
      )}

      <FormField label="Module Title" required error={errors.module_title?.message as string}>
        <Input {...register('module_title')} placeholder="e.g. Pemrograman Dasar" />
      </FormField>

      <div className="grid grid-cols-2 gap-3">
        <FormField label="Sequence" required error={errors.sequence?.message as string}>
          <Input type="number" min={1} {...register('sequence', { valueAsNumber: true })} />
        </FormField>
        <FormField label="Duration (jam)" error={errors.duration_hours?.message as string}>
          <Input type="number" min={0} step={0.5} {...register('duration_hours', { valueAsNumber: true })} />
        </FormField>
      </div>

      <FormField label="Content Depth" error={errors.content_depth?.message as string}>
        <Textarea {...register('content_depth')} rows={3} />
      </FormField>

      <FormField label="Assessment Method" error={errors.assessment_method?.message as string}>
        <Input {...register('assessment_method')} placeholder="e.g. Project + Quiz" />
      </FormField>

      <FormField label="Topics">
        <Controller name="topics" control={control}
          render={({ field }) => <MultiInput value={field.value ?? []} onChange={field.onChange} placeholder="Add topic" />} />
      </FormField>

      <FormField label="Practical Activities">
        <Controller name="practical_activities" control={control}
          render={({ field }) => <MultiInput value={field.value ?? []} onChange={field.onChange} placeholder="Add activity" />} />
      </FormField>

      <FormField label="Tools Required">
        <Controller name="tools_required" control={control}
          render={({ field }) => <MultiInput value={field.value ?? []} onChange={field.onChange} placeholder="Add tool" />} />
      </FormField>

      <FormField label="Requirements">
        <Controller name="requirements" control={control}
          render={({ field }) => <MultiInput value={field.value ?? []} onChange={field.onChange} placeholder="Add requirement" />} />
      </FormField>

      <div className="flex gap-2 pt-2 border-t border-neutral-100">
        <Button type="button" variant="secondary" onClick={onCancel}>Cancel</Button>
        <Button type="submit" loading={isSubmitting} disabled={isSubmitting}>Save</Button>
      </div>
    </form>
  )
}
```

- [ ] **Step 6.2: Typecheck + commit**

---

## Task 7: ModulesSection

- [ ] **Step 7.1: Implement container**

`frontend/src/portals/internal/components/curriculum/ModulesSection.tsx`:
```tsx
import { useState } from 'react'
import { Plus, Lock } from 'lucide-react'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { useCourseModules } from '@/lib/api/curriculum'
import ModuleList from './ModuleList'
import ModuleForm from './ModuleForm'
import type { CourseModule } from '@/types/coursemodule'
import type { CourseVersion } from '@/types/courseversion'

interface Props { version: CourseVersion }

type FormState =
  | { open: false }
  | { open: true; mode: 'create' }
  | { open: true; mode: 'edit'; module: CourseModule }

export default function ModulesSection({ version }: Props) {
  const locked = version.status === 'approved' || version.status === 'archived'
  const { data: modules } = useCourseModules(version.id)
  const [form, setForm] = useState<FormState>({ open: false })

  const count = modules?.length ?? 0
  const nextSequence = count + 1

  return (
    <div className="space-y-3 pt-4 border-t border-neutral-100">
      <div className="flex items-center justify-between">
        <h4 className="text-sm font-semibold text-neutral-700">
          Modules ({count})
        </h4>
        {locked ? (
          <span className="inline-flex items-center gap-1.5 text-xs text-neutral-500">
            <Lock className="w-3.5 h-3.5" /> Version {version.status} — read-only
          </span>
        ) : (
          <RoleGate action="create" resource="coursemodule">
            <Button size="sm" onClick={() => setForm({ open: true, mode: 'create' })}>
              <Plus className="w-4 h-4" /> Add Module
            </Button>
          </RoleGate>
        )}
      </div>

      <ModuleList
        versionId={version.id}
        locked={locked}
        onEdit={(m) => setForm({ open: true, mode: 'edit', module: m })}
      />

      {form.open && (
        <div className="bg-white border border-neutral-200 rounded-xl p-5">
          <ModuleForm
            versionId={version.id}
            mode={form.mode === 'create'
              ? { kind: 'create', defaultSequence: nextSequence }
              : { kind: 'edit', module: form.module }}
            onSuccess={() => setForm({ open: false })}
            onCancel={() => setForm({ open: false })}
          />
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 7.2: Typecheck + commit**

---

## Task 8: Wire into VersionDetailPanel

- [ ] **Step 8.1: Render ModulesSection**

In `VersionDetailPanel.tsx`:

Add import:
```tsx
import ModulesSection from './ModulesSection'
```

After the Changelog `<pre>` block (and closing `</div>`), before the outermost `</div>`, add:
```tsx
<ModulesSection version={v} />
```

- [ ] **Step 8.2: Typecheck + tests + commit**

```
cd frontend && npm run typecheck && npm test
```

Expected: typecheck pass, all tests (incl. 6 new module tests) pass.

```bash
git add frontend/src/portals/internal/components/curriculum/VersionDetailPanel.tsx
git commit -m "feat(curriculum): wire ModulesSection into VersionDetailPanel"
```

---

## Task 9: Smoke Verify

- [ ] **Step 9.1: Run dev**

API + frontend up.

- [ ] **Step 9.2: 12 manual smoke**

Per spec §6 — execute scenarios 1-12.

- [ ] **Step 9.3: Final verify**
```
cd frontend && npm run typecheck && npm test
```

---

## Done Criteria

- [ ] @dnd-kit deps installed
- [ ] Type + zod schema + 6 tests
- [ ] 5 react-query hooks
- [ ] 4 components (ModuleRow, ModuleList, ModuleForm, ModulesSection)
- [ ] VersionDetailPanel renders ModulesSection
- [ ] Lock applies when version approved/archived
- [ ] DnD reorder persists
- [ ] typecheck clean, vitest hijau
- [ ] 12 smoke pass (or documented blockers)
- [ ] All commits on `feat/curriculum-iter-1d`

Setelah merge → Iter 1E (CertificateTemplate + InternshipConfig + CharacterTestConfig + reference modules).
