import * as RadixSwitch from '@radix-ui/react-switch'
import { cn } from '@/lib/utils/cn'

interface SwitchProps extends React.ComponentPropsWithoutRef<typeof RadixSwitch.Root> {
  label?: string
}

export default function Switch({ className, label, ...props }: SwitchProps) {
  return (
    <div className="flex items-center gap-2">
      <RadixSwitch.Root
        className={cn(
          'peer inline-flex h-5 w-9 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-brand-600 data-[state=unchecked]:bg-neutral-200',
          className,
        )}
        {...props}
      >
        <RadixSwitch.Thumb className="pointer-events-none block h-4 w-4 rounded-full bg-white shadow-lg ring-0 transition-transform data-[state=checked]:translate-x-4 data-[state=unchecked]:translate-x-0" />
      </RadixSwitch.Root>
      {label && <span className="text-sm text-neutral-700">{label}</span>}
    </div>
  )
}
