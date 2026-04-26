import { useState } from 'react'
import * as Tabs from '@radix-ui/react-tabs'
import { useAuth } from '@/lib/auth/useAuth'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const TABS = [
  { value: 'confirmed', label: 'Active' },
  { value: 'completed', label: 'Completed' },
  { value: 'dropped', label: 'Dropped' },
]

const COLUMNS: Column<Enrollment>[] = [
  { header: 'Batch', accessor: 'batch_id' },
  {
    header: 'Enrolled',
    accessor: 'enrolled_at',
    cell: (row) => formatDate(row.enrolled_at),
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
          <div className="h-full bg-brand-500 rounded-full" style={{ width: `${row.completion_percent}%` }} />
        </div>
        <span className="text-xs text-neutral-500">{row.completion_percent}%</span>
      </div>
    ),
  },
  {
    header: 'Certificate',
    accessor: 'certificate_id',
    cell: (row) =>
      row.certificate_id ? (
        <span className="text-xs text-emerald-600 font-medium">Issued</span>
      ) : (
        <span className="text-xs text-neutral-400">—</span>
      ),
  },
]

export default function MyEnrollments() {
  const { user } = useAuth()
  const [activeTab, setActiveTab] = useState('confirmed')
  const [page, setPage] = useState(1)
  const LIMIT = 10

  const { data, isLoading } = useEnrollments({
    student_id: user?.id,
    status: activeTab,
    page,
    limit: LIMIT,
  })

  return (
    <div className="space-y-6">
      <PageHeader
        title="My Enrollments"
        breadcrumbs={[{ label: 'My Enrollments' }]}
      />

      <Tabs.Root value={activeTab} onValueChange={(v) => { setActiveTab(v); setPage(1) }}>
        <Tabs.List className="flex border-b border-border mb-4">
          {TABS.map((tab) => (
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

        {TABS.map((tab) => (
          <Tabs.Content key={tab.value} value={tab.value}>
            <DataTable
              columns={COLUMNS}
              data={data?.data ?? []}
              loading={isLoading}
              pagination={data ? { page, limit: LIMIT, total: data.total } : undefined}
              onPageChange={setPage}
              rowKey={(row) => row.id}
            />
          </Tabs.Content>
        ))}
      </Tabs.Root>
    </div>
  )
}
