import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useMarketingPr } from '@/lib/api/marketing'
import { PR_TYPES, PR_STATUSES, type MarketingPr } from '@/types/marketingpr'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import StatusBadge from '@/components/shared/StatusBadge'

const LIMIT = 15

const COLUMNS: Column<MarketingPr>[] = [
  {
    header: 'Scheduled',
    accessor: 'scheduled_at',
    cell: (r) => (
      <span className="text-sm">{new Date(r.scheduled_at).toLocaleString()}</span>
    ),
    className: 'w-44',
  },
  { header: 'Type', accessor: 'type', className: 'w-32' },
  {
    header: 'Title',
    accessor: 'title',
    cell: (r) => (
      <span className="text-sm text-neutral-900 line-clamp-1">{r.title}</span>
    ),
  },
  {
    header: 'Media / Venue',
    accessor: 'media_venue',
    cell: (r) => (
      <span className="text-sm text-neutral-700 line-clamp-1">{r.media_venue}</span>
    ),
  },
  { header: 'PIC', accessor: 'pic_name', className: 'w-40' },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} />,
    className: 'w-32',
  },
]

export default function MarketingPR() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('')
  const [type, setType] = useState('')

  const { data, isLoading } = useMarketingPr({
    page,
    limit: LIMIT,
    status: status || undefined,
    type: type || undefined,
  })

  return (
    <ListPageTemplate
      title="Marketing PR"
      subtitle="Interviews, press releases, events, podcasts"
      actions={
        <RoleGate action="create" resource="marketing_post">
          <Button onClick={() => navigate('/internal/marketing/pr/new')}>
            <Plus className="w-4 h-4" /> New PR
          </Button>
        </RoleGate>
      }
      filters={
        <div className="flex gap-2 flex-wrap">
          <select
            value={type}
            onChange={(e) => { setType(e.target.value); setPage(1) }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
          >
            <option value="">All types</option>
            {PR_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
          <select
            value={status}
            onChange={(e) => { setStatus(e.target.value); setPage(1) }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
          >
            <option value="">All statuses</option>
            {PR_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
        </div>
      }
      columns={COLUMNS}
      data={data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: (data ?? []).length === LIMIT ? page * LIMIT + 1 : (page - 1) * LIMIT + (data ?? []).length }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/marketing/pr/${r.id}/edit`)}
    />
  )
}
