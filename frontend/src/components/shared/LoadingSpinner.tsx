import { cn } from '@/lib/utils/cn'

type SpinnerSize = 'sm' | 'md' | 'lg'

const SIZE_CLASS: Record<SpinnerSize, string> = {
  sm: 'w-4 h-4 border-2',
  md: 'w-8 h-8 border-2',
  lg: 'w-12 h-12 border-4',
}

interface LoadingSpinnerProps {
  size?: SpinnerSize
  className?: string
}

export default function LoadingSpinner({ size = 'md', className }: LoadingSpinnerProps) {
  return (
    <div className={cn('flex items-center justify-center', className)}>
      <div
        className={cn(
          'rounded-full border-brand-200 border-t-brand-600 animate-spin',
          SIZE_CLASS[size]
        )}
      />
    </div>
  )
}
