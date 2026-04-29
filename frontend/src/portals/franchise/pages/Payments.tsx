import { useState, useMemo } from 'react'
import { useInvoices, type Invoice } from '@/lib/api/finance'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import { Column } from '@/components/shared/DataTable'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'
import ListPageTemplate from '@/components/templates/ListPageTemplate'

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
    <ListPageTemplate
      title="Payments"
      subtitle="Invoice and payment history"
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(row) => row.id}
    />
  )
}
