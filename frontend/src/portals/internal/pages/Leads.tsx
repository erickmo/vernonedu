import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useLeads } from '@/lib/api/lead'
import { LEAD_STATUSES, LEAD_SOURCES, type Lead } from '@/types/lead'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import StatusBadge from '@/components/shared/StatusBadge'

const LIMIT = 15

const COLUMNS: Column<Lead>[] = [
  { header: 'Name', accessor: 'name' },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} />,
    className: 'w-32',
  },
  { header: 'Source', accessor: 'source', className: 'w-32' },
  { header: 'Interest', accessor: 'interest' },
  {
    header: 'Created',
    accessor: 'created_at',
    cell: (r) => (
      <span className="text-sm text-neutral-600">
        {new Date(r.created_at).toLocaleDateString()}
      </span>
    ),
    className: 'w-32',
  },
]

export default function Leads() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('')
  const [source, setSource] = useState('')

  const { data, isLoading } = useLeads({
    page,
    limit: LIMIT,
    status: status || undefined,
    source: source || undefined,
  })

  return (
    <ListPageTemplate
      title="Leads"
      subtitle="Manage potential customers"
      actions={
        <RoleGate action="create" resource="lead">
          <Button onClick={() => navigate('/internal/leads/new')}>
            <Plus className="w-4 h-4" /> Add Lead
          </Button>
        </RoleGate>
      }
      filters={
        <div className="flex gap-2">
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value)
              setPage(1)
            }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
          >
            <option value="">All statuses</option>
            {LEAD_STATUSES.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
          <select
            value={source}
            onChange={(e) => {
              setSource(e.target.value)
              setPage(1)
            }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
          >
            <option value="">All sources</option>
            {LEAD_SOURCES.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
      }
      columns={COLUMNS}
      data={data?.data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/leads/${r.id}`)}
    />
  )
}
