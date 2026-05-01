import { useState, useMemo } from 'react'
import { toast } from 'sonner'
import { useRoyaltyRecords, useMarkRoyaltyPaid, type RoyaltyRecord } from '@/lib/api/franchise'
import { useFranchiseeCtx } from '../FranchiseeContext'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const ROYALTY_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Unpaid', value: 'unpaid' },
  { label: 'Overdue', value: 'overdue' },
  { label: 'Paid', value: 'paid' },
]

export default function Royalty() {
  const { franchisee } = useFranchiseeCtx()
  const [activeTab, setActiveTab] = useState('')
  const [confirmItem, setConfirmItem] = useState<RoyaltyRecord | null>(null)

  const handleTabChange = useMemo(
    () => (v: string) => setActiveTab(v),
    [],
  )

  useSubNav(ROYALTY_TABS, activeTab, handleTabChange)

  const { data: records = [], isLoading } = useRoyaltyRecords(franchisee.id)
  const markPaid = useMarkRoyaltyPaid()

  const filtered = activeTab ? records.filter((r) => r.status === activeTab) : records

  const handleConfirm = async () => {
    if (!confirmItem) return
    try {
      await markPaid.mutateAsync(confirmItem.id)
      toast.success('Royalty marked as paid')
      setConfirmItem(null)
    } catch {
      toast.error('Failed to mark royalty as paid')
    }
  }

  const columns: Column<RoyaltyRecord>[] = [
    {
      header: 'Period',
      accessor: 'period',
      cell: (row) => <span className="font-mono text-sm font-medium text-neutral-800">{row.period}</span>,
    },
    {
      header: 'Gross Revenue',
      accessor: 'gross_revenue',
      cell: (row) => <span className="font-mono text-sm text-neutral-700">{formatCurrency(Number(row.gross_revenue))}</span>,
    },
    {
      header: 'Monthly Royalty',
      accessor: 'monthly_royalty',
      cell: (row) => <span className="font-mono text-sm text-neutral-700">{formatCurrency(Number(row.monthly_royalty))}</span>,
    },
    {
      header: 'Total Royalty',
      accessor: 'total_royalty',
      cell: (row) => <span className="font-mono text-sm font-semibold text-neutral-800">{formatCurrency(Number(row.total_royalty))}</span>,
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => {
        const colors: Record<string, string> = {
          paid: 'bg-emerald-100 text-emerald-700',
          unpaid: 'bg-amber-100 text-amber-700',
          overdue: 'bg-red-100 text-red-700',
        }
        return (
          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${colors[row.status] ?? 'bg-neutral-100 text-neutral-700'}`}>
            {row.status.charAt(0).toUpperCase() + row.status.slice(1)}
          </span>
        )
      },
    },
    {
      header: 'Paid At',
      accessor: 'paid_at',
      cell: (row) => <span className="text-xs text-neutral-500">{row.paid_at ? formatDate(row.paid_at) : '—'}</span>,
    },
    {
      header: '',
      accessor: 'id',
      cell: (row) =>
        row.status !== 'paid' ? (
          <button
            onClick={() => setConfirmItem(row)}
            className="inline-flex items-center px-2.5 py-1 text-xs font-medium text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors"
          >
            Mark Paid
          </button>
        ) : null,
    },
  ]

  return (
    <div className="space-y-5">
      <PageHeader title="Royalty Records" subtitle="Monthly royalty payments for your franchise" />
      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={columns}
          data={filtered}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>
      <ConfirmDialog
        open={!!confirmItem}
        title="Mark Royalty as Paid"
        description={`Mark royalty for period ${confirmItem?.period ?? ''} as paid?`}
        onConfirm={handleConfirm}
        onCancel={() => setConfirmItem(null)}
      />
    </div>
  )
}
