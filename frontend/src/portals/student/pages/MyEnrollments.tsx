import { useState, useMemo } from 'react'
import { useAuth } from '@/lib/auth/useAuth'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const ENROLLMENT_TABS: SubNavItem[] = [
  { label: 'Active', value: 'confirmed' },
  { label: 'Completed', value: 'completed' },
  { label: 'Dropped', value: 'dropped' },
]

const LIMIT = 10

const COLUMNS: Column<Enrollment>[] = [
  { header: 'Batch', accessor: 'batch_id' },
  {
    header: 'Enrolled',
    accessor: 'enrolled_at',
    cell: (row) => (
      <span className="text-xs text-neutral-500">{formatDate(row.enrolled_at)}</span>
    ),
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
    header: 'Certificate',
    accessor: 'certificate_id',
    cell: (row) =>
      row.certificate_id ? (
        <span className="text-xs font-medium text-emerald-600">Issued</span>
      ) : (
        <span className="text-xs text-neutral-400">—</span>
      ),
  },
]

export default function MyEnrollments() {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState('confirmed')
  const [page, setPage] = useState(1)

  const handleTabChange = useMemo(
    () => (v: string) => { setActiveTab(v); setPage(1) },
    [],
  )

  useSubNav(ENROLLMENT_TABS, activeTab, handleTabChange)

  const { data, isLoading } = useEnrollments({
    student_id: user?.id,
    status: activeTab,
    page,
    limit: LIMIT,
  })

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">My Enrollments</h1>
        <p className="text-sm text-neutral-500 mt-0.5">Track your enrolled courses</p>
      </div>

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
