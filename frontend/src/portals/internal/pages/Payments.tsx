import { useState } from 'react'
import { Check, X } from 'lucide-react'
import * as Tabs from '@radix-ui/react-tabs'
import { toast } from 'sonner'
import { useInvoices, useUpdateInvoiceStatus, type Invoice } from '@/lib/api/finance'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { cn } from '@/lib/utils/cn'

export default function Payments() {
  const [activeTab, setActiveTab] = useState('pending')
  const [page, setPage] = useState(1)
  const [confirmItem, setConfirmItem] = useState<Invoice | null>(null)
  const LIMIT = 15

  const updateStatus = useUpdateInvoiceStatus()

  const { data, isLoading } = useInvoices({
    status: activeTab === 'pending' ? 'sent' : undefined,
    page,
    limit: LIMIT,
  })

  const handleConfirm = async () => {
    if (!confirmItem) return
    try {
      await updateStatus.mutateAsync({ id: confirmItem.id, status: 'paid' })
      toast.success('Payment confirmed')
      setConfirmItem(null)
    } catch {
      toast.error('Failed to confirm payment')
    }
  }

  const columns: Column<Invoice>[] = [
    { header: 'Invoice #', accessor: 'number' },
    {
      header: 'Amount',
      accessor: 'total',
      cell: (row) => <span className="font-medium">{formatCurrency(row.total)}</span>,
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} variant="invoice" />,
    },
    {
      header: 'Due Date',
      accessor: 'due_date',
      cell: (row) => formatDate(row.due_date),
    },
    {
      header: 'Issued',
      accessor: 'issued_date',
      cell: (row) => formatDate(row.issued_date),
    },
    ...(activeTab === 'pending'
      ? [
          {
            header: 'Actions',
            accessor: 'id' as keyof Invoice,
            cell: (row: Invoice) => (
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setConfirmItem(row)}
                  className="flex items-center gap-1 px-2.5 py-1 text-xs font-medium text-white bg-emerald-600 rounded-md hover:bg-emerald-700 transition-colors"
                >
                  <Check className="w-3.5 h-3.5" />
                  Confirm
                </button>
                <button className="flex items-center gap-1 px-2.5 py-1 text-xs font-medium text-red-600 border border-red-200 rounded-md hover:bg-red-50 transition-colors">
                  <X className="w-3.5 h-3.5" />
                  Reject
                </button>
              </div>
            ),
          } as Column<Invoice>,
        ]
      : []),
  ]

  return (
    <div className="space-y-5">
      <PageHeader title="Payments" subtitle="Review and confirm incoming payments" breadcrumbs={[{ label: 'Payments' }]} />

      <Tabs.Root value={activeTab} onValueChange={(v) => { setActiveTab(v); setPage(1) }}>
        <Tabs.List className="flex border-b border-border mb-4">
          {[{ value: 'pending', label: 'Pending Confirmation' }, { value: 'all', label: 'All Invoices' }].map((tab) => (
            <Tabs.Trigger
              key={tab.value}
              value={tab.value}
              className={cn(
                'px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors',
                'data-[state=active]:border-brand-600 data-[state=active]:text-brand-700',
                'data-[state=inactive]:border-transparent data-[state=inactive]:text-neutral-500 data-[state=inactive]:hover:text-neutral-700'
              )}
            >
              {tab.label}
            </Tabs.Trigger>
          ))}
        </Tabs.List>

        <Tabs.Content value={activeTab}>
          <DataTable
            columns={columns}
            data={data?.data ?? []}
            loading={isLoading}
            pagination={data ? { page, limit: LIMIT, total: data.total } : undefined}
            onPageChange={setPage}
            rowKey={(row) => row.id}
          />
        </Tabs.Content>
      </Tabs.Root>

      <ConfirmDialog
        open={!!confirmItem}
        title="Confirm Payment"
        description={`Confirm payment for invoice ${confirmItem?.number}?`}
        confirmLabel="Confirm Payment"
        onConfirm={handleConfirm}
        onCancel={() => setConfirmItem(null)}
      />
    </div>
  )
}
