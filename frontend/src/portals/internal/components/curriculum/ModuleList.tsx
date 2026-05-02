import { useEffect, useState } from 'react'
import { toast } from 'sonner'
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core'
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import {
  useCourseModules,
  useUpdateCourseModule,
  useDeleteCourseModule,
} from '@/lib/api/curriculum'
import ModuleRow from './ModuleRow'
import type { CourseModule } from '@/types/coursemodule'
import type { UpdateCourseModuleInput } from '@/schemas/coursemodule'

interface Props {
  versionId: string
  locked: boolean
  onEdit: (m: CourseModule) => void
}

function moduleToUpdateInput(m: CourseModule, sequence: number): UpdateCourseModuleInput {
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
    if (oldIndex < 0 || newIndex < 0) return
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
        description={`Delete "${pendingDelete?.module_title ?? ''}"? This cannot be undone.`}
        confirmLabel="Delete"
        destructive
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
