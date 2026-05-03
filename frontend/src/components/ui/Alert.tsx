import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils/cn'

const alertVariants = cva(
  'relative w-full rounded-lg border p-4 text-sm',
  {
    variants: {
      variant: {
        default: 'bg-white border-border text-neutral-800',
        success: 'bg-emerald-50 border-emerald-200 text-emerald-800',
        warning: 'bg-amber-50 border-amber-200 text-amber-800',
        danger: 'bg-red-50 border-red-200 text-red-800',
        info: 'bg-blue-50 border-blue-200 text-blue-800',
      },
    },
    defaultVariants: { variant: 'default' },
  },
)

interface AlertProps extends React.HTMLAttributes<HTMLDivElement>, VariantProps<typeof alertVariants> {}

export default function Alert({ variant, className, ...props }: AlertProps) {
  return <div role="alert" className={cn(alertVariants({ variant }), className)} {...props} />
}
