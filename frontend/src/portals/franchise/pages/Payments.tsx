import { useState, useMemo } from 'react'
import { useInvoices, type Invoice } from '@/lib/api/finance'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const PAYMENT_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'sent' },
  { label: 'Paid', value: 'paid' },
  { label: 'Overdue', value: 'overdue' },
]

const LIMIT = 15

const COLUMNS: Column<Invoice>[] = [
  {
    header: 'Invoice #',
    accessor: 'number',
    cell: (row) => <span className="font-mono text-xs text-neutral-700">{row.number}</span>,
  },
  {
    header: 'Amount',
    accessor: 'total',
    cell: (row) => <span className="font-semibold text-neutral-800 font-mono">{formatCurrency(row.total)}</span>,
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => <StatusBadge status={row.status} variant="invoice" />,
  },
  {
    header: 'Due Date',
    accessor: 'due_date',
    cell: (row) => <span className="text-xs text-neutral-500">{formatDate(row.due_date)}</span>,
  },
  {
    header: 'Issued',
    accessor: 'issued_date',
    cell: (row) => <span className="text-xs text-neutral-500">{formatDate(row.issued_date)}</span>,
  },
  {
    header: 'Paid At',
    accessor: 'paid_date',
    cell: (row) => <span className="text-xs text-neutral-500">{row.paid_date ? formatDate(row.paid_date) : '—'}</span>,
  },
]

export default function FranchisePayments() {
  const [activeTab, setActiveTab] = useState('')
  const [page, setPage] = useState(1)

  const handleTabChange = useMemo(
    () => (v: string) => { setActiveTab(v); setPage(1) },
    [],
  )

  useSubNav(PAYMENT_TABS, activeTab, handleTabChange)

  const { data, isLoading } = useInvoices({
    status: activeTab || undefined,
    page,
    limit: LIMIT,
  })

  return (
    <div className="space-y-5">
      <PageHeader title="Payments" subtitle="Invoice and payment history" />
      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
        />
      </div>
    </div>
  )
}
