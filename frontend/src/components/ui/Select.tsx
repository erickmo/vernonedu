import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  error?: boolean
}

const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ error, className, ...props }, ref) => (
    <select
      ref={ref}
      className={cn(
        'w-full px-3 py-2.5 text-sm border rounded-lg bg-white transition-colors',
        'focus:outline-none focus:ring-2 focus:ring-brand-500',
        error ? 'border-red-300 focus:ring-red-400' : 'border-neutral-200',
        className
      )}
      {...props}
    />
  )
)
Select.displayName = 'Select'
export default Select
