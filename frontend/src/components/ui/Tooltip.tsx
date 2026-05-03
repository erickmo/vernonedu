import * as RadixTooltip from '@radix-ui/react-tooltip'
import { cn } from '@/lib/utils/cn'

export const TooltipProvider = RadixTooltip.Provider
export const Tooltip = RadixTooltip.Root
export const TooltipTrigger = RadixTooltip.Trigger

interface TooltipContentProps extends React.ComponentPropsWithoutRef<typeof RadixTooltip.Content> {
  side?: 'top' | 'right' | 'bottom' | 'left'
}

export function TooltipContent({ className, side = 'top', children, ...props }: TooltipContentProps) {
  return (
    <RadixTooltip.Portal>
      <RadixTooltip.Content
        side={side}
        sideOffset={6}
        className={cn(
          'z-50 rounded-lg bg-neutral-900 px-3 py-1.5 text-xs text-white shadow-dropdown animate-fade-in',
          className,
        )}
        {...props}
      >
        {children}
      </RadixTooltip.Content>
    </RadixTooltip.Portal>
  )
}