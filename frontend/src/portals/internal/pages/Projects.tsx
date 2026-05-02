import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useProjects } from '@/lib/api/project'
import { PROJECT_STATUSES, type Project, type ProjectStatus } from '@/types/project'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Select from '@/components/ui/Select'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'

const LIMIT = 15

const STATUS_CLASS: Record<ProjectStatus, string> = {
  planning: 'bg-sky-50 text-sky-700',
  active: 'bg-emerald-50 text-emerald-700',
  completed: 'bg-neutral-100 text-neutral-600',
  cancelled: 'bg-rose-50 text-rose-700',
  on_hold: 'bg-amber-50 text-amber-700',
}

const COLUMNS: Column<Project>[] = [
  { header: 'Code', accessor: 'code' },
  { header: 'Name', accessor: 'name' },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => (
      <span className={`inline-flex px-2 py-0.5 rounded-full text-xs ${STATUS_CLASS[r.status]}`}>
        {r.status.replace('_', ' ')}
      </span>
    ),
  },
  { header: 'Start', accessor: 'start_date' },
  { header: 'End', accessor: 'end_date' },
  {
    header: 'Budget',
    accessor: 'budget',
    cell: (r) => <span className="text-sm">Rp {r.budget.toLocaleString()}</span>,
  },
]

export default function Projects() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState<string>('')

  const { data, isLoading } = useProjects({
    page,
    limit: LIMIT,
    status: (status || undefined) as any,
  })

  return (
    <ListPageTemplate
      title="Projects"
      subtitle="One-time events and initiatives"
      actions={
        <div className="flex gap-2">
          <Select value={status} onChange={(e) => setStatus(e.target.value)}>
            <option value="">All statuses</option>
            {PROJECT_STATUSES.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </Select>
          <RoleGate action="create" resource="project">
            <Button onClick={() => navigate('/internal/projects/new')}>
              <Plus className="w-4 h-4" /> Add Project
            </Button>
          </RoleGate>
        </div>
      }
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/projects/${r.id}`)}
    />
  )
}
