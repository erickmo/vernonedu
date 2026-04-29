import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { usePartners, useCreatePartner, type Partner } from '@/lib/api/businessops'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const PARTNER_TYPE_LABELS: Record<Partner['type'], string> = {
  university: 'University',
  vendor: 'Vendor',
  sponsor: 'Sponsor',
  franchise_candidate: 'Franchise Candidate',
  community: 'Community',
  other: 'Other',
}

const PARTNER_TYPE_OPTIONS: Partner['type'][] = [
  'university', 'vendor', 'sponsor', 'franchise_candidate', 'community', 'other',
]

const partnerSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  type: z.enum(['university', 'vendor', 'sponsor', 'franchise_candidate', 'community', 'other']),
  contact_name: z.string().optional(),
  contact_email: z.string().email('Invalid email').optional().or(z.literal('')),
  contact_phone: z.string().optional(),
  notes: z.string().optional(),
})

type PartnerForm = z.infer<typeof partnerSchema>

const COLUMNS: Column<Partner>[] = [
  { header: 'Name', accessor: 'name' },
  {
    header: 'Type',
    accessor: 'type',
    cell: (row) => (
      <span className="text-sm">{PARTNER_TYPE_LABELS[row.type]}</span>
    ),
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => (
      <span
        className={cn(
          'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
          row.status === 'active'
            ? 'bg-emerald-50 text-emerald-700'
            : row.status === 'lead'
            ? 'bg-amber-50 text-amber-700'
            : 'bg-neutral-100 text-neutral-500',
        )}
      >
        {row.status.charAt(0).toUpperCase() + row.status.slice(1)}
      </span>
    ),
  },
  {
    header: 'Contact',
    accessor: 'contact_name',
    cell: (row) => (
      <span className="text-sm text-neutral-500">{row.contact_name ?? '—'}</span>
    ),
  },
  {
    header: 'Created',
    accessor: 'created_at',
    cell: (row) => formatDate(row.created_at),
  },
]

export default function Partners() {
  const navigate = useNavigate()
  const [open, setOpen] = useState(false)
  const { data = [], isLoading } = usePartners()
  const createPartner = useCreatePartner()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<PartnerForm>({
    resolver: zodResolver(partnerSchema),
    defaultValues: { type: 'other' },
  })

  const onSubmit = async (form: PartnerForm) => {
    try {
      await createPartner.mutateAsync({
        ...form,
        contact_email: form.contact_email || undefined,
      })
      toast.success('Partner added')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to add partner')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Partners"
        subtitle={isLoading ? 'Loading…' : `${data.length} partner${data.length !== 1 ? 's' : ''}`}
        actions={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Partner
          </button>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        <DataTable
          columns={COLUMNS}
          data={data}
          loading={isLoading}
          rowKey={(row) => row.id}
          onRowClick={(row) => navigate(`/internal/partners/${row.id}`)}
        />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-50" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">
              Add Partner
            </Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Name <span className="text-red-500">*</span>
                </label>
                <input
                  {...register('name')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.name && (
                  <p className="text-xs text-red-500 mt-1">{errors.name.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Type
                </label>
                <select
                  {...register('type')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  {PARTNER_TYPE_OPTIONS.map((t) => (
                    <option key={t} value={t}>
                      {PARTNER_TYPE_LABELS[t]}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Contact Name
                </label>
                <input
                  {...register('contact_name')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Contact Email
                </label>
                <input
                  {...register('contact_email')}
                  type="email"
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.contact_email && (
                  <p className="text-xs text-red-500 mt-1">{errors.contact_email.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Contact Phone
                </label>
                <input
                  {...register('contact_phone')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Notes
                </label>
                <textarea
                  {...register('notes')}
                  rows={3}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none"
                />
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
                  disabled={createPartner.isPending}
                  className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createPartner.isPending ? 'Adding…' : 'Add Partner'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
