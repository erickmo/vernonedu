import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useCourseBatches } from '@/lib/api/coursebatch'
import type { CourseBatch } from '@/types/coursebatch'
import { Column } from '@/components/shared/DataTable'
import StatusBadge from '@/components/shared/StatusBadge'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 15

const BATCH_STATUSES = ['draft', 'open', 'full', 'ongoing', 'completed', 'cancelled'] as const

const COLUMNS: Column<CourseBatch>[] = [
  { header: 'Code', accessor: 'code', className: 'font-mono text-xs w-28' },
  { header: 'Name', accessor: 'name' },
  {
    header: 'Period',
    accessor: 'start_date',
    cell: (r) =>
      `${formatDate(r.start_date)} → ${formatDate(r.end_date)}`,
  },
  {
    header: 'Participants',
    accessor: 'max_participants',
    cell: (r) => `${r.enrollment_count ?? 0} / ${r.max_participants}`,
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} variant="batch" />,
  },
]

function formatDate(s: string) {
  if (!s) return '—'
  try {
    return new Date(s).toLocaleDateString()
  } catch {
    return s
  }
}

export default function Batches() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState<string>('')
  const [courseId, setCourseId] = useState<string>('')

  const { data, isLoading } = useCourseBatches({
    page,
    limit: LIMIT,
    status: status || undefined,
    course_id: courseId || undefined,
  })

  return (
    <ListPageTemplate
      title="Course Batches"
      subtitle="Manage real-world batches (kelas)"
      actions={
        <RoleGate action="create" resource="coursebatch">
          <Button onClick={() => navigate('/internal/batches/new')}>
            <Plus className="w-4 h-4" /> Add Batch
          </Button>
        </RoleGate>
      }
      filters={
        <div className="flex gap-2">
          <select
            value={status}
            onChange={(e) => { setPage(1); setStatus(e.target.value) }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg"
          >
            <option value="">All status</option>
            {BATCH_STATUSES.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
          <input
            type="text"
            value={courseId}
            onChange={(e) => { setPage(1); setCourseId(e.target.value) }}
            placeholder="Filter by course UUID"
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg w-72 font-mono"
          />
        </div>
      }
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/batches/${r.id}`)}
    />
  )
}
