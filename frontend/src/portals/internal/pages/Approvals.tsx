import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useApprovals } from '@/lib/api/approval'
import { APPROVAL_STATUSES, type Approval, type ApprovalStatus } from '@/types/approval'
import { Column } from '@/components/shared/DataTable'
import { cn } from '@/lib/utils/cn'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Select from '@/components/ui/Select'
import { useAuth } from '@/lib/auth/useAuth'

const LIMIT = 15

const STATUS_CLASS: Record<ApprovalStatus, string> = {
  pending: 'bg-amber-50 text-amber-700',
  approved: 'bg-emerald-50 text-emerald-700',
  rejected: 'bg-rose-50 text-rose-700',
  cancelled: 'bg-neutral-100 text-neutral-500',
}

const COLUMNS: Column<Approval>[] = [
  { header: 'Title', accessor: 'title' },
  {
    header: 'Type',
    accessor: 'type',
    cell: (r) => <span className="text-sm">{r.type.replace(/_/g, ' ')}</span>,
  },
  {
    header: 'Requested By',
    accessor: 'requested_by_name',
    cell: (r) => <span className="text-sm">{r.requested_by_name ?? r.requested_by_id}</span>,
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => (
      <span
        className={cn(
          'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
          STATUS_CLASS[r.status],
        )}
      >
        {r.status}
      </span>
    ),
  },
  {
    header: 'Created',
    accessor: 'created_at',
    cell: (r) => new Date(r.created_at).toLocaleDateString(),
  },
]

export default function Approvals() {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [page, setPage] = useState(1)
  const [statusFilter, setStatusFilter] = useState<ApprovalStatus | ''>('pending')
  const [scope, setScope] = useState<'mine' | 'all'>('mine')

  const { data, isLoading } = useApprovals({
    page,
    limit: LIMIT,
    status: statusFilter || undefined,
    approver_id: scope === 'mine' ? user?.id : undefined,
  })

  return (
    <ListPageTemplate
      title="Approvals"
      subtitle="Review approval requests"
      actions={
        <div className="flex gap-2">
          <Select value={scope} onChange={(e) => setScope(e.target.value as 'mine' | 'all')}>
            <option value="mine">Assigned to me</option>
            <option value="all">All</option>
          </Select>
          <Select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as ApprovalStatus | '')}
          >
            <option value="">All statuses</option>
            {APPROVAL_STATUSES.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </Select>
        </div>
      }
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/approvals/${r.id}`)}
    />
  )
}
