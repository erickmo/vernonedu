import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Plus } from 'lucide-react'
import { useCmsArticles } from '@/lib/api/cms'
import {
  ARTICLE_STATUSES,
  ARTICLE_CATEGORIES,
  type CmsArticle,
} from '@/types/cmsarticle'
import { Column } from '@/components/shared/DataTable'
import ListPageTemplate from '@/components/templates/ListPageTemplate'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import StatusBadge from '@/components/shared/StatusBadge'

const LIMIT = 15

const COLUMNS: Column<CmsArticle>[] = [
  { header: 'Title', accessor: 'title' },
  { header: 'Category', accessor: 'category', className: 'w-32' },
  {
    header: 'Status',
    accessor: 'status',
    cell: (r) => <StatusBadge status={r.status} />,
    className: 'w-32',
  },
  {
    header: 'Updated',
    accessor: 'updated_at',
    cell: (r) => (
      <span className="text-sm text-neutral-600">
        {new Date(r.updated_at).toLocaleDateString()}
      </span>
    ),
    className: 'w-32',
  },
]

export default function Articles() {
  const navigate = useNavigate()
  const [page, setPage] = useState(1)
  const [status, setStatus] = useState('')
  const [category, setCategory] = useState('')

  const { data, isLoading } = useCmsArticles({
    page,
    limit: LIMIT,
    status: status || undefined,
    category: category || undefined,
  })

  return (
    <ListPageTemplate
      title="Articles"
      subtitle="Blog posts, news, success stories"
      actions={
        <RoleGate action="create" resource="cms_article">
          <Button onClick={() => navigate('/internal/cms/articles/new')}>
            <Plus className="w-4 h-4" /> New Article
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
            {ARTICLE_STATUSES.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
          <select
            value={category}
            onChange={(e) => {
              setCategory(e.target.value)
              setPage(1)
            }}
            className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
          >
            <option value="">All categories</option>
            {ARTICLE_CATEGORIES.map((c) => (
              <option key={c} value={c}>{c}</option>
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
      onRowClick={(r) => navigate(`/internal/cms/articles/${r.slug}/edit`)}
    />
  )
}
