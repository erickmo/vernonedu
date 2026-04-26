import { formatCurrency } from '@/lib/utils/format'
import { cn } from '@/lib/utils/cn'

interface PriceBreakdownProps {
  basePrice: number
  voucherDiscount?: number
  creditApplied?: number
  total: number
}

interface LineItemProps {
  label: string
  amount: number
  strikethrough?: boolean
  highlight?: boolean
  negative?: boolean
}

function LineItem({ label, amount, strikethrough, highlight, negative }: LineItemProps) {
  return (
    <div className={cn('flex justify-between items-center py-1.5', highlight && 'font-semibold')}>
      <span className={cn('text-sm', highlight ? 'text-neutral-900' : 'text-neutral-600')}>
        {label}
      </span>
      <span
        className={cn(
          'text-sm',
          strikethrough && 'line-through text-neutral-400',
          highlight && 'text-neutral-900 text-base',
          negative && 'text-emerald-600',
          !strikethrough && !highlight && !negative && 'text-neutral-700'
        )}
      >
        {negative ? `-${formatCurrency(amount)}` : formatCurrency(amount)}
      </span>
    </div>
  )
}

export default function PriceBreakdown({
  basePrice,
  voucherDiscount,
  creditApplied,
  total,
}: PriceBreakdownProps) {
  const hasDiscount = (voucherDiscount ?? 0) > 0 || (creditApplied ?? 0) > 0

  return (
    <div className="rounded-lg border border-border p-4 space-y-1">
      <LineItem
        label="Course price"
        amount={basePrice}
        strikethrough={hasDiscount}
      />
      {(voucherDiscount ?? 0) > 0 && (
        <LineItem label="Voucher discount" amount={voucherDiscount!} negative />
      )}
      {(creditApplied ?? 0) > 0 && (
        <LineItem label="Credit applied" amount={creditApplied!} negative />
      )}
      <div className="border-t border-border pt-1.5 mt-1.5">
        <LineItem label="Total" amount={total} highlight />
      </div>
    </div>
  )
}
