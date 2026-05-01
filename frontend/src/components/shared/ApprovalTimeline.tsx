import { Check, X, Clock, Minus } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import { formatDateTime } from '@/lib/utils/format'

type StepStatus = 'pending' | 'approved' | 'rejected' | 'waiting'

interface TimelineStep {
  label: string
  status: StepStatus
  actor?: string
  timestamp?: string
  note?: string
}

interface ApprovalTimelineProps {
  steps: TimelineStep[]
}

const STATUS_CONFIG: Record<StepStatus, { icon: typeof Check; dotClass: string; iconClass: string }> = {
  approved: { icon: Check, dotClass: 'bg-emerald-500 border-emerald-500', iconClass: 'text-white' },
  rejected: { icon: X, dotClass: 'bg-red-500 border-red-500', iconClass: 'text-white' },
  pending: { icon: Clock, dotClass: 'bg-amber-400 border-amber-400', iconClass: 'text-white' },
  waiting: { icon: Minus, dotClass: 'bg-white border-neutral-300', iconClass: 'text-neutral-400' },
}

export default function ApprovalTimeline({ steps }: ApprovalTimelineProps) {
  return (
    <ol className="relative space-y-0">
      {steps.map((step, idx) => {
        const cfg = STATUS_CONFIG[step.status]
        const Icon = cfg.icon
        const isLast = idx === steps.length - 1

        return (
          <li key={idx} className="flex gap-4">
            <div className="flex flex-col items-center">
              <div
                className={cn(
                  'w-8 h-8 rounded-full border-2 flex items-center justify-center shrink-0 z-10',
                  cfg.dotClass
                )}
              >
                <Icon className={cn('w-4 h-4', cfg.iconClass)} />
              </div>
              {!isLast && <div className="w-0.5 bg-neutral-200 flex-1 my-1" />}
            </div>

            <div className={cn('pb-6', isLast && 'pb-0')}>
              <p className="text-sm font-medium text-neutral-800">{step.label}</p>
              {step.actor && (
                <p className="text-xs text-neutral-500 mt-0.5">by {step.actor}</p>
              )}
              {step.timestamp && (
                <p className="text-xs text-neutral-400 mt-0.5">{formatDateTime(step.timestamp)}</p>
              )}
              {step.note && (
                <p className="text-xs text-neutral-500 mt-1 italic bg-neutral-50 rounded px-2 py-1">
                  {step.note}
                </p>
              )}
            </div>
          </li>
        )
      })}
    </ol>
  )
}
