import { CheckCircle2 } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import StatusBadge from '@/components/shared/StatusBadge'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import type { Batch } from '@/lib/api/catalog'

interface BatchCardProps {
  batch: Batch
  selected: boolean
  onSelect: () => void
}

export default function BatchCard({ batch, selected, onSelect }: BatchCardProps) {
  const isSelectable = batch.status === 'open'

  return (
    <button
      type="button"
      onClick={isSelectable ? onSelect : undefined}
      disabled={!isSelectable}
      className={cn(
        'w-full text-left rounded-xl border p-4 transition-all',
        'shadow-[0_1px_3px_rgba(0,0,0,0.06)]',
        isSelectable
          ? 'cursor-pointer hover:border-brand-300 hover:shadow-md'
          : 'cursor-not-allowed opacity-50 bg-neutral-50',
        selected
          ? 'border-brand-500 ring-2 ring-brand-500/20 bg-brand-50/30'
          : 'border-neutral-100 bg-white',
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="space-y-1 flex-1 min-w-0">
          <p className="font-semibold text-sm text-neutral-900 truncate">
            {batch.label}
          </p>
          <p className="text-xs text-neutral-500">
            {formatDate(batch.start_date)} – {formatDate(batch.end_date)}
          </p>
          <p className="text-sm font-bold text-brand-700">
            {formatCurrency(batch.price)}
          </p>
        </div>
        <div className="flex flex-col items-end gap-2 shrink-0">
          <StatusBadge status={batch.status} variant="batch" />
          {selected && (
            <CheckCircle2 className="w-5 h-5 text-brand-600" />
          )}
        </div>
      </div>
    </button>
  )
}
