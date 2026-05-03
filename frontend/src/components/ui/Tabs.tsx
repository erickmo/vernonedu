import * as RadixTabs from '@radix-ui/react-tabs'
import { cn } from '@/lib/utils/cn'

export const Tabs = RadixTabs.Root

export function TabsList({ className, ...props }: React.ComponentPropsWithoutRef<typeof RadixTabs.List>) {
  return (
    <RadixTabs.List
      className={cn('inline-flex items-center gap-1 rounded-lg bg-neutral-100 p-1', className)}
      {...props}
    />
  )
}

export function TabsTrigger({ className, ...props }: React.ComponentPropsWithoutRef<typeof RadixTabs.Trigger>) {
  return (
    <RadixTabs.Trigger
      className={cn(
        'inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1.5 text-sm font-medium text-neutral-600 transition-all focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-white data-[state=active]:text-neutral-900 data-[state=active]:shadow-sm',
        className,
      )}
      {...props}
    />
  )
}

export function TabsContent({ className, ...props }: React.ComponentPropsWithoutRef<typeof RadixTabs.Content>) {
  return (
    <RadixTabs.Content
      className={cn('mt-3 focus-visible:outline-none', className)}
      {...props}
    />
  )
}
