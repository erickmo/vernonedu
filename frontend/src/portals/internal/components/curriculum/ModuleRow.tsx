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
        'grid grid-cols-[24px_40px_120px_1fr_80px_60px_80px] items-center gap-3 px-3 py-2 border-b border-neutral-100 bg-white last:border-b-0',
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
      ) : (
        <span />
      )}

      <div className="text-sm text-neutral-500">{m.sequence}</div>
      <div className="text-sm font-mono text-neutral-700 truncate">{m.module_code}</div>
      <div className="text-sm text-neutral-900 truncate">{m.module_title}</div>
      <div className="text-xs text-neutral-500">{m.duration_hours} jam</div>
      <div className="text-xs text-neutral-500">{m.tools_required.length}</div>
      <div className="flex items-center gap-1 justify-end">
        {!locked && (
          <>
            <button
              type="button"
              onClick={onEdit}
              className="p-1 text-neutral-500 hover:text-brand-600"
              aria-label="Edit"
            >
              <Pencil className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={onDelete}
              className="p-1 text-neutral-500 hover:text-red-600"
              aria-label="Delete"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </>
        )}
      </div>
    </div>
  )
}
