import { useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const STATUS_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'pending' },
  { label: 'Confirmed', value: 'confirmed' },
  { label: 'Completed', value: 'completed' },
  { label: 'Dropped', value: 'dropped' },
]

const LIMIT = 15

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
        <span className="text-xs text-neutral-500 font-mono tabular-nums">
          {row.completion_percent}%
        </span>
      </div>
    ),
  },
  {
    header: 'Enrolled',
    accessor: 'enrolled_at',
    cell: (row) => <span className="text-xs text-neutral-500">{formatDate(row.enrolled_at)}</span>,
  },
]

export default function Enrollments() {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('')
  const [page, setPage] = useState(1)

  const handleTabChange = useMemo(
    () => (v: string) => { setActiveTab(v); setPage(1) },
    [],
  )

  useSubNav(STATUS_TABS, activeTab, handleTabChange)

  const { data, isLoading } = useEnrollments({
    status: activeTab || undefined,
    page,
    limit: LIMIT,
  })

  return (
    <ListPageTemplate
      title="Enrollments"
      subtitle="Manage all student enrollments"
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(row) => row.id}
      onRowClick={(row) => navigate(`/internal/enrollments/${row.id}`)}
    />
  )
}
