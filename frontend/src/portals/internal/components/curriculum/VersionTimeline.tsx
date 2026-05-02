import { cn } from '@/lib/utils/cn'
import type { CourseVersion } from '@/types/courseversion'

interface Props {
  versions: CourseVersion[]
  selectedId?: string
  onSelect: (id: string) => void
}

function fmtDate(s: string) {
  return new Date(s).toLocaleDateString('id-ID', { year: 'numeric', month: 'short', day: 'numeric' })
}

function statusClass(status: CourseVersion['status']) {
  switch (status) {
    case 'draft': return 'bg-neutral-100 text-neutral-700'
    case 'review': return 'bg-amber-100 text-amber-800'
    case 'approved': return 'bg-emerald-100 text-emerald-800'
    case 'archived': return 'bg-slate-200 text-slate-500'
  }
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
              <span className={cn(
                'inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium capitalize',
                statusClass(v.status),
              )}>
                {v.status}
              </span>
            </div>
            <div className="text-xs text-neutral-500 mt-1">{fmtDate(v.created_at)}</div>
            <div className="text-xs text-neutral-400 capitalize">{v.change_type}</div>
          </button>
        )
      })}
    </div>
  )
}
