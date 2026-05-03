import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

interface ProgressProps extends React.HTMLAttributes<HTMLDivElement> {
  value?: number
  max?: number
}

const Progress = forwardRef<HTMLDivElement, ProgressProps>(
  ({ value = 0, max = 100, className, ...props }, ref) => {
    const pct = Math.min(100, Math.max(0, (value / max) * 100))
    return (
      <div ref={ref} className={cn('relative h-2 w-full overflow-hidden rounded-full bg-neutral-100', className)} {...props}>
        <div className="h-full rounded-full bg-brand-600 transition-all duration-300 ease-out" style={{ width: `${pct}%` }} />
      </div>
    )
  },
)
Progress.displayName = 'Progress'
export default Progress
