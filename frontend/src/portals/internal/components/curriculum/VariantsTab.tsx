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
