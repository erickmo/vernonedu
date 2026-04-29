import { useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Check } from 'lucide-react'
import { toast } from 'sonner'
import { useInvoices, useUpdateInvoiceStatus, type Invoice } from '@/lib/api/finance'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const PAYMENT_TABS: SubNavItem[] = [
  { label: 'Pending', value: 'pending' },
  { label: 'All', value: 'all' },
]

const LIMIT = 15

export default function Payments() {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('pending')
  const [page, setPage] = useState(1)
  const [confirmItem, setConfirmItem] = useState<Invoice | null>(null)

  const handleTabChange = useMemo(
    () => (v: string) => { setActiveTab(v); setPage(1) },
    [],
  )

  useSubNav(PAYMENT_TABS, activeTab, handleTabChange)

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
    {
      header: 'Invoice #',
      accessor: 'number',
      cell: (row) => (
        <span className="font-mono text-xs text-neutral-700">{row.number}</span>
      ),
    },
    {
      header: 'Amount',
      accessor: 'total',
      cell: (row) => (
        <span className="font-semibold text-neutral-800 font-mono">
          {formatCurrency(row.total)}
        </span>
      ),
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} variant="invoice" />,
    },
    {
      header: 'Due Date',
      accessor: 'due_date',
      cell: (row) => (
        <span className="text-xs text-neutral-500">{formatDate(row.due_date)}</span>
      ),
    },
    {
      header: 'Issued',
      accessor: 'issued_date',
      cell: (row) => (
        <span className="text-xs text-neutral-500">{formatDate(row.issued_date)}</span>
      ),
    },
    ...(activeTab === 'pending'
      ? [
          {
            header: 'Actions',
            accessor: 'id' as keyof Invoice,
            cell: (row: Invoice) => (
              <div className="flex items-center gap-1.5">
                <button
                  onClick={() => setConfirmItem(row)}
                  className="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-medium text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors"
                >
                  <Check className="w-3 h-3" /> Confirm
                </button>
              </div>
            ),
          } as Column<Invoice>,
        ]
      : []),
  ]

  return (
    <div className="space-y-5">
      <PageHeader title="Payments" subtitle="Invoice and payment management" />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
          onRowClick={(row) => navigate(`/internal/payments/${row.id}`)}
        />
      </div>

      <ConfirmDialog
        open={!!confirmItem}
        title="Confirm Payment"
        description={`Mark invoice ${confirmItem?.number ?? ''} as paid?`}
        onConfirm={handleConfirm}
        onCancel={() => setConfirmItem(null)}
      />
    </div>
  )
}
