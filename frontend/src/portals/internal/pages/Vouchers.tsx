import { useState } from 'react'
import { Plus } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useVouchers, useCreateVoucher, type Voucher } from '@/lib/api/businessops'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const DISCOUNT_TYPE_LABELS: Record<Voucher['discount_type'], string> = {
  fixed_amount: 'Fixed Amount',
  percentage: 'Percentage',
  fixed_final_price: 'Fixed Final Price',
}

const DISCOUNT_TYPE_OPTIONS: Voucher['discount_type'][] = [
  'fixed_amount', 'percentage', 'fixed_final_price',
]

const voucherSchema = z.object({
  code: z.string().min(3, 'Code must be at least 3 characters'),
  discount_type: z.enum(['fixed_amount', 'percentage', 'fixed_final_price']),
  discount_value: z.string().min(1, 'Discount value is required'),
  valid_from: z.string().min(1, 'Valid from is required'),
  valid_until: z.string().optional(),
  max_uses: z.coerce.number().int().positive().optional().or(z.literal('')),
})

type VoucherForm = z.infer<typeof voucherSchema>

const COLUMNS: Column<Voucher>[] = [
  {
    header: 'Code',
    accessor: 'code',
    cell: (row) => (
      <span className="font-mono text-sm font-medium">{row.code}</span>
    ),
  },
  {
    header: 'Type',
    accessor: 'discount_type',
    cell: (row) => (
      <span className="text-sm">{DISCOUNT_TYPE_LABELS[row.discount_type]}</span>
    ),
  },
  {
    header: 'Value',
    accessor: 'discount_value',
    cell: (row) => (
      <span className="font-mono text-sm">{row.discount_value}</span>
    ),
  },
  {
    header: 'Used / Max',
    accessor: 'used_count',
    cell: (row) => (
      <span className="text-sm text-neutral-600">
        {row.used_count} / {row.max_uses ?? '∞'}
      </span>
    ),
  },
  {
    header: 'Status',
    accessor: 'is_active',
    cell: (row) => (
      <span
        className={cn(
          'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
          row.is_active
            ? 'bg-emerald-50 text-emerald-700'
            : 'bg-neutral-100 text-neutral-500',
        )}
      >
        {row.is_active ? 'Active' : 'Inactive'}
      </span>
    ),
  },
  {
    header: 'Valid From',
    accessor: 'valid_from',
    cell: (row) => formatDate(row.valid_from),
  },
]

export default function Vouchers() {
  const [open, setOpen] = useState(false)
  const { data = [], isLoading } = useVouchers()
  const createVoucher = useCreateVoucher()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<VoucherForm>({
    resolver: zodResolver(voucherSchema),
    defaultValues: { discount_type: 'fixed_amount' },
  })

  const onSubmit = async (form: VoucherForm) => {
    try {
      await createVoucher.mutateAsync({
        code: form.code.toUpperCase(),
        discount_type: form.discount_type,
        discount_value: form.discount_value,
        valid_from: form.valid_from,
        valid_until: form.valid_until || undefined,
        max_uses: form.max_uses === '' ? undefined : (form.max_uses as number | undefined),
      })
      toast.success('Voucher created')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to create voucher')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Vouchers"
        subtitle={isLoading ? 'Loading…' : `${data.length} voucher${data.length !== 1 ? 's' : ''}`}
        actions={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Create Voucher
          </button>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        <DataTable
          columns={COLUMNS}
          data={data}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">
              Create Voucher
            </Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Code <span className="text-red-500">*</span>
                </label>
                <input
                  {...register('code')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono uppercase focus:outline-none focus:ring-2 focus:ring-brand-500"
                  placeholder="e.g. SAVE20"
                />
                {errors.code && (
                  <p className="text-xs text-red-500 mt-1">{errors.code.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Discount Type
                </label>
                <select
                  {...register('discount_type')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  {DISCOUNT_TYPE_OPTIONS.map((t) => (
                    <option key={t} value={t}>
                      {DISCOUNT_TYPE_LABELS[t]}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Discount Value <span className="text-red-500">*</span>
                </label>
                <input
                  {...register('discount_value')}
                  type="number"
                  step="any"
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.discount_value && (
                  <p className="text-xs text-red-500 mt-1">{errors.discount_value.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Valid From <span className="text-red-500">*</span>
                </label>
                <input
                  {...register('valid_from')}
                  type="datetime-local"
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.valid_from && (
                  <p className="text-xs text-red-500 mt-1">{errors.valid_from.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Valid Until
                </label>
                <input
                  {...register('valid_until')}
                  type="datetime-local"
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Max Uses
                </label>
                <input
                  {...register('max_uses')}
                  type="number"
                  min="1"
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                  placeholder="Leave blank for unlimited"
                />
                {errors.max_uses && (
                  <p className="text-xs text-red-500 mt-1">{String(errors.max_uses.message)}</p>
                )}
              </div>

              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => { setOpen(false); reset() }}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createVoucher.isPending}
                  className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createVoucher.isPending ? 'Creating…' : 'Create Voucher'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
