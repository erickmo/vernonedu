import { useState } from 'react'
import { useClassDocPosts } from '@/lib/api/marketing'
import type { ClassDocPost } from '@/types/classdocpost'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import StatusBadge from '@/components/shared/StatusBadge'

const LIMIT = 15

const COLUMNS: Column<ClassDocPost>[] = [
  {
    header: 'Scheduled',
    accessor: 'scheduled_at',
    cell: (r) => (
      <span className="text-sm">{new Date(r.scheduled_at).toLocaleString()}</span>
    ),
    className: 'w-44',
  },
  { header: 'Type', accessor: 'content_type', className: 'w-24' },
  {
    header: 'Caption',
    accessor: 'caption',
    cell: (r) => <span className="text-sm line-clamp-1">{r.caption}</span>,
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} />,
    className: 'w-32',
  },
]

export default function ClassDocPosts() {
  const [page, setPage] = useState(1)
  const { data, isLoading } = useClassDocPosts({ page, limit: LIMIT })

  const items = data ?? []

  return (
    <ListPageTemplate
      title="Class Documentation"
      subtitle="Auto-scheduled posts after each session"
      columns={COLUMNS}
      data={items}
      loading={isLoading}
      pagination={{
        page,
        limit: LIMIT,
        total: items.length === LIMIT ? page * LIMIT + 1 : (page - 1) * LIMIT + items.length,
      }}
      onPageChange={setPage}
      rowKey={(r) => r.id}
    />
  )
}
