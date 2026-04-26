import { useState } from 'react'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'

const COLUMNS: Column<Enrollment>[] = [
  { header: 'Student', accessor: 'student_id' },
  { header: 'Batch', accessor: 'batch_id' },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => <StatusBadge status={row.status} variant="enrollment" />,
  },
  {
    header: 'Payment',
    accessor: 'payment_status',
    cell: (row) => <StatusBadge status={row.payment_status} variant="payment" />,
  },
  {
    header: 'Progress',
    accessor: 'completion_percent',
    cell: (row) => (
      <div className="flex items-center gap-2">
        <div className="w-20 h-1.5 bg-neutral-100 rounded-full overflow-hidden">
          <div
            className="h-full bg-brand-500 rounded-full"
            style={{ width: `${row.completion_percent}%` }}
          />
        </div>
        <span className="text-xs text-neutral-500">{row.completion_percent}%</span>
      </div>
    ),
  },
  {
    header: 'Enrolled',
    accessor: 'enrolled_at',
    cell: (row) => <span className="text-xs">{formatDate(row.enrolled_at)}</span>,
  },
]

export default function Enrollments() {
  const [page, setPage] = useState(1)
  const [statusFilter, setStatusFilter] = useState('')
  const [paymentFilter, setPaymentFilter] = useState('')
  const LIMIT = 15

  const { data, isLoading } = useEnrollments({
    status: statusFilter || undefined,
    payment_status: paymentFilter || undefined,
    page,
    limit: LIMIT,
  })

  return (
    <div className="space-y-5">
      <PageHeader
        title="Enrollments"
        subtitle="Manage all student enrollments"
        breadcrumbs={[{ label: 'Enrollments' }]}
      />

      <div className="flex flex-wrap gap-3">
        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
          className="px-3 py-2 text-sm border border-border rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
        >
          <option value="">All statuses</option>
          <option value="pending">Pending</option>
          <option value="confirmed">Confirmed</option>
          <option value="dropped">Dropped</option>
          <option value="completed">Completed</option>
        </select>

        <select
          value={paymentFilter}
          onChange={(e) => { setPaymentFilter(e.target.value); setPage(1) }}
          className="px-3 py-2 text-sm border border-border rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-brand-500"
        >
          <option value="">All payment statuses</option>
          <option value="pending">Pending</option>
          <option value="partial">Partial</option>
          <option value="paid">Paid</option>
          <option value="overdue">Overdue</option>
        </select>
      </div>

      <DataTable
        columns={COLUMNS}
        data={data?.data ?? []}
        loading={isLoading}
        pagination={data ? { page, limit: LIMIT, total: data.total } : undefined}
        onPageChange={setPage}
        rowKey={(row) => row.id}
      />
    </div>
  )
}
