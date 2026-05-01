import { forwardRef } from 'react'
import { cn } from '@/lib/utils/cn'

interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  error?: boolean
}

const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ error, className, ...props }, ref) => (
    <textarea
      ref={ref}
      className={cn(
        'w-full px-3 py-2.5 text-sm border rounded-lg bg-white transition-colors resize-none',
        'focus:outline-none focus:ring-2 focus:ring-brand-500',
        error ? 'border-red-300 focus:ring-red-400' : 'border-neutral-200',
        className
      )}
      {...props}
    />
  )
)
Textarea.displayName = 'Textarea'
export default Textarea
