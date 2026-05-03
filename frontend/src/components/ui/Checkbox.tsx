import * as RadixCheckbox from '@radix-ui/react-checkbox'
import { Check } from 'lucide-react'
import { cn } from '@/lib/utils/cn'

interface CheckboxProps extends React.ComponentPropsWithoutRef<typeof RadixCheckbox.Root> {
  label?: string
}

export default function Checkbox({ className, label, ...props }: CheckboxProps) {
  return (
    <div className="flex items-center gap-2">
      <RadixCheckbox.Root
        className={cn(
          'peer h-4 w-4 shrink-0 rounded border border-neutral-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-brand-600 data-[state=checked]:border-brand-600 data-[state=checked]:text-white',
          className,
        )}
        {...props}
      >
        <RadixCheckbox.Indicator className="flex items-center justify-center text-current">
          <Check className="h-3 w-3" />
        </RadixCheckbox.Indicator>
      </RadixCheckbox.Root>
      {label && <label className="text-sm text-neutral-700 cursor-pointer" onClick={() => props.onCheckedChange?.(!props.checked)}>{label}</label>}
    </div>
  )
}
