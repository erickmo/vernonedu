import * as RadixScrollArea from '@radix-ui/react-scroll-area'
import { cn } from '@/lib/utils/cn'

interface ScrollAreaProps {
  orientation?: 'vertical' | 'horizontal' | 'both'
  className?: string
  children?: React.ReactNode
}

export default function ScrollArea({ orientation = 'vertical', className, children }: ScrollAreaProps) {
  return (
    <RadixScrollArea.Root className={cn('relative overflow-hidden', className)}>
      <RadixScrollArea.Viewport className="h-full w-full rounded-[inherit]">
        {children}
      </RadixScrollArea.Viewport>
      <RadixScrollArea.Scrollbar
        orientation={orientation === 'horizontal' ? 'horizontal' : 'vertical'}
        className="flex touch-none select-none p-0.5 transition-colors hover:bg-neutral-100"
      >
        <RadixScrollArea.Thumb className="relative flex-1 rounded-full bg-neutral-300" />
      </RadixScrollArea.Scrollbar>
      {orientation === 'both' && (
        <RadixScrollArea.Scrollbar orientation="horizontal" className="flex touch-none select-none p-0.5 transition-colors hover:bg-neutral-100">
          <RadixScrollArea.Thumb className="relative flex-1 rounded-full bg-neutral-300" />
        </RadixScrollArea.Scrollbar>
      )}
      <RadixScrollArea.Corner />
    </RadixScrollArea.Root>
  )
}
