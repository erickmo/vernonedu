import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useMarketingPosts } from '@/lib/api/marketing'
import {
  POST_PLATFORMS,
  POST_STATUSES,
  type MarketingPost,
} from '@/types/marketingpost'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import StatusBadge from '@/components/shared/StatusBadge'

const LIMIT = 15

const COLUMNS: Column<MarketingPost>[] = [
  {
    header: 'Scheduled',
    accessor: 'scheduled_at',
    cell: (r) => (
      <span className="text-sm">{new Date(r.scheduled_at).toLocaleString()}</span>
    ),
    className: 'w-44',
  },
  {
    header: 'Platforms',
    accessor: 'platforms',
    cell: (r) => (
      <span className="text-sm">{(r.platforms ?? []).join(', ')}</span>
    ),
  },
  { header: 'Type', accessor: 'content_type', className: 'w-24' },
  {
    header: 'Caption',
    accessor: 'caption',
    cell: (r) => (
      <span className="text-sm text-neutral-700 line-clamp-1">{r.caption}</span>
    ),
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} />,
    className: 'w-32',
  },
]

export default function MarketingPosts() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [platform, setPlatform] = useState('')
  const [status, setStatus] = useState('')
  const [month, setMonth] = useState('')

  const { data, isLoading } = useMarketingPosts({
    page,
    limit: LIMIT,
    platform: platform || undefined,
    status: status || undefined,
    month: month || undefined,
  })

  return (
    <ListPageTemplate
      title="Marketing Posts"
      subtitle="Scheduled social media content"
      actions={
        <RoleGate action="create" resource="marketing_post">
          <Button onClick={() => navigate('/internal/marketing/posts/new')}>
            <Plus className="w-4 h-4" /> New Post
          </Button>
        </RoleGate>
      }
      filters={
        <div className="flex gap-2 flex-wrap">
          <select
            value={platform}
            onChange={(e) => { setPlatform(e.target.value); setPage(1) }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
          >
            <option value="">All platforms</option>
            {POST_PLATFORMS.map((p) => <option key={p} value={p}>{p}</option>)}
          </select>
          <select
            value={status}
            onChange={(e) => { setStatus(e.target.value); setPage(1) }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
          >
            <option value="">All statuses</option>
            {POST_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
          <input
            type="month"
            value={month}
            onChange={(e) => { setMonth(e.target.value); setPage(1) }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
          />
        </div>
      }
      columns={COLUMNS}
      data={data ?? []}
      loading={isLoading}
      pagination={{ page, limit: LIMIT, total: (data ?? []).length === LIMIT ? page * LIMIT + 1 : (page - 1) * LIMIT + (data ?? []).length }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
      onRowClick={(r) => navigate(`/internal/marketing/posts/${r.id}/edit`)}
    />
  )
}
