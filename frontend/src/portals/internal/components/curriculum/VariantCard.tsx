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
