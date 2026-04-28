import { useState } from 'react'
import { Plus, ArrowRight } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import {
  useFranchisees,
  useCreateFranchisee,
  useRoyaltyRecords,
  useMarkRoyaltyPaid,
  type Franchisee,
  type RoyaltyRecord,
} from '@/lib/api/franchise'
import { formatCurrency } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

// ── Constants ─────────────────────────────────────────────────────────────────

const TABS = ['Franchisees', 'Royalty'] as const
type Tab = (typeof TABS)[number]

const franchiseeSchema = z.object({
  name: z.string().min(2, 'Name required'),
  branch_name: z.string().min(2, 'Branch name required'),
  location: z.string().min(2, 'Location required'),
  contact: z.string().min(5, 'Contact required'),
})

type FranchiseeForm = z.infer<typeof franchiseeSchema>

// ── Sub-components ────────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: Franchisee['status'] }) {
  const styles: Record<Franchisee['status'], string> = {
    active: 'bg-emerald-50 text-emerald-700',
    inactive: 'bg-neutral-100 text-neutral-500',
    terminated: 'bg-red-50 text-red-700',
  }
  return (
    <span
      className={cn(
        'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium capitalize',
        styles[status],
      )}
    >
      {status}
    </span>
  )
}

function RoyaltyStatusBadge({ status }: { status: RoyaltyRecord['status'] }) {
  const styles: Record<RoyaltyRecord['status'], string> = {
    paid: 'bg-emerald-50 text-emerald-700',
    unpaid: 'bg-amber-50 text-amber-700',
    overdue: 'bg-red-50 text-red-700',
  }
  return (
    <span
      className={cn(
        'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium capitalize',
        styles[status],
      )}
    >
      {status}
    </span>
  )
}

// ── Add Franchisee Dialog ─────────────────────────────────────────────────────

function AddFranchiseeDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (v: boolean) => void }) {
  const createFranchisee = useCreateFranchisee()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FranchiseeForm>({ resolver: zodResolver(franchiseeSchema) })

  const onSubmit = async (form: FranchiseeForm) => {
    try {
      await createFranchisee.mutateAsync(form)
      toast.success('Franchisee created')
      onOpenChange(false)
      reset()
    } catch {
      toast.error('Failed to create franchisee')
    }
  }

  const FIELDS: { key: keyof FranchiseeForm; label: string; placeholder: string }[] = [
    { key: 'name', label: 'Franchisee Name', placeholder: 'e.g. PT Vernonedu Bandung' },
    { key: 'branch_name', label: 'Branch Name', placeholder: 'e.g. Bandung Utara' },
    { key: 'location', label: 'Location', placeholder: 'e.g. Bandung, Jawa Barat' },
    { key: 'contact', label: 'Contact', placeholder: 'Phone or email' },
  ]

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 animate-in fade-in-0" />
        <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-2xl shadow-xl p-6 animate-in fade-in-0 zoom-in-95">
          <Dialog.Title className="text-lg font-bold text-neutral-900 mb-5">
            Add Franchisee
          </Dialog.Title>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            {FIELDS.map(({ key, label, placeholder }) => (
              <div key={key} className="space-y-1.5">
                <label className="text-sm font-medium text-neutral-700">{label}</label>
                <input
                  {...register(key)}
                  placeholder={placeholder}
                  className="w-full px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors[key] && (
                  <p className="text-xs text-red-600">{errors[key]?.message}</p>
                )}
              </div>
            ))}

            <div className="flex justify-end gap-2 pt-2">
              <Dialog.Close asChild>
                <button
                  type="button"
                  className="px-4 py-2 text-sm font-medium text-neutral-600 border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors"
                >
                  Cancel
                </button>
              </Dialog.Close>
              <button
                type="submit"
                disabled={createFranchisee.isPending}
                className="px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50 transition-colors"
              >
                {createFranchisee.isPending ? 'Creating…' : 'Create Franchisee'}
              </button>
            </div>
          </form>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}

// ── Franchisees Tab ───────────────────────────────────────────────────────────

function FranchiseesTab({
  onViewRoyalty,
}: {
  onViewRoyalty: (franchisee: Franchisee) => void
}) {
  const { data, isLoading } = useFranchisees()
  const [dialogOpen, setDialogOpen] = useState(false)

  const COLUMNS: Column<Franchisee>[] = [
    { header: 'Name', accessor: 'name' },
    { header: 'Branch Name', accessor: 'branch_name' },
    { header: 'Location', accessor: 'location' },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} />,
    },
    {
      header: '',
      accessor: 'id',
      className: 'text-right',
      cell: (row) => (
        <button
          onClick={() => onViewRoyalty(row)}
          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-brand-600 border border-brand-200 rounded-lg hover:bg-brand-50 transition-colors"
        >
          View Royalty
          <ArrowRight className="w-3 h-3" />
        </button>
      ),
    },
  ]

  return (
    <>
      <div className="flex justify-end mb-4">
        <button
          onClick={() => setDialogOpen(true)}
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors shadow-sm"
        >
          <Plus className="w-4 h-4" />
          Add Franchisee
        </button>
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data ?? []}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>

      <AddFranchiseeDialog open={dialogOpen} onOpenChange={setDialogOpen} />
    </>
  )
}

// ── Royalty Tab ───────────────────────────────────────────────────────────────

function RoyaltyTab({ selectedFranchisee }: { selectedFranchisee: Franchisee | null }) {
  const { data, isLoading } = useRoyaltyRecords(selectedFranchisee?.id ?? '')
  const markPaid = useMarkRoyaltyPaid()

  const handleMarkPaid = async (id: string) => {
    try {
      await markPaid.mutateAsync(id)
      toast.success('Royalty record marked as paid')
    } catch {
      toast.error('Failed to mark as paid')
    }
  }

  const COLUMNS: Column<RoyaltyRecord>[] = [
    { header: 'Period', accessor: 'period' },
    {
      header: 'Gross Revenue',
      accessor: 'gross_revenue',
      cell: (row) => (
        <span className="font-mono text-sm">{formatCurrency(row.gross_revenue)}</span>
      ),
    },
    {
      header: 'Total Royalty',
      accessor: 'total_royalty',
      cell: (row) => (
        <span className="font-mono text-sm">{formatCurrency(row.total_royalty)}</span>
      ),
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <RoyaltyStatusBadge status={row.status} />,
    },
    {
      header: '',
      accessor: 'id',
      className: 'text-right',
      cell: (row) =>
        row.status !== 'paid' ? (
          <button
            onClick={() => handleMarkPaid(row.id)}
            disabled={markPaid.isPending}
            className="px-3 py-1.5 text-xs font-medium text-emerald-700 border border-emerald-200 rounded-lg hover:bg-emerald-50 transition-colors disabled:opacity-50"
          >
            Mark Paid
          </button>
        ) : null,
    },
  ]

  if (!selectedFranchisee) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <p className="text-sm text-neutral-500">
          Select a franchisee to view royalty records
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2 py-2">
        <span className="text-sm text-neutral-500">Showing royalty records for:</span>
        <span className="text-sm font-semibold text-neutral-900">{selectedFranchisee.name}</span>
        <StatusBadge status={selectedFranchisee.status} />
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data ?? []}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>
    </div>
  )
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function Franchises() {
  const [activeTab, setActiveTab] = useState<Tab>('Franchisees')
  const [selectedFranchisee, setSelectedFranchisee] = useState<Franchisee | null>(null)

  const handleViewRoyalty = (franchisee: Franchisee) => {
    setSelectedFranchisee(franchisee)
    setActiveTab('Royalty')
  }

  return (
    <div className="space-y-5">
      <PageHeader
        title="Franchises"
        subtitle="Manage franchisees and royalty records"
        breadcrumbs={[{ label: 'Franchises' }]}
      />

      {/* Tabs */}
      <div className="flex items-center gap-1 bg-white border border-neutral-200 rounded-lg p-1 w-fit">
        {TABS.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={cn(
              'px-4 py-1.5 text-sm font-medium rounded-md transition-colors',
              activeTab === tab
                ? 'bg-brand-600 text-white shadow-sm'
                : 'text-neutral-600 hover:bg-neutral-50',
            )}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Tab content */}
      {activeTab === 'Franchisees' ? (
        <FranchiseesTab onViewRoyalty={handleViewRoyalty} />
      ) : (
        <RoyaltyTab selectedFranchisee={selectedFranchisee} />
      )}
    </div>
  )
}
