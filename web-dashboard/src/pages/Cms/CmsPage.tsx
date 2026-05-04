import { useNavigate } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { cmsService } from '@/services/cms.service'
import type { ListParams } from '@/services/createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

interface Article {
  id: string
  title?: string
  slug?: string
  category?: string
  status?: string
  created_at?: number
  [key: string]: unknown
}

function formatDate(ts: number | undefined): string {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  }).format(new Date(ts * 1000))
}

async function fetchArticles(params: ListParams): Promise<PaginatedResponse<Article>> {
  const raw = await cmsService.listArticles(params)
  const items: Article[] = Array.isArray(raw?.items) ? raw.items : (Array.isArray(raw) ? raw : [])
  return { items, total: raw?.total ?? items.length, offset: 0, limit: params.limit ?? 100 }
}

const columns: ColumnDef<Article>[] = [
  {
    key: 'title',
    header: 'Judul',
    sortable: true,
    render: (_v, row) => (
      <div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.title ?? '(Tanpa judul)'}
        </div>
        {row.slug && (
          <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
            /{row.slug}
          </div>
        )}
      </div>
    ),
  },
  {
    key: 'category',
    header: 'Kategori',
    width: 140,
    render: (_v, row) => row.category ?? '—',
  },
  {
    key: 'status',
    header: 'Status',
    width: 110,
    align: 'center',
    render: (_v, row) => {
      const isPublished = row.status === 'published'
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: isPublished ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
          color: isPublished ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
        }}>
          {row.status ?? '—'}
        </span>
      )
    },
  },
  {
    key: 'created_at',
    header: 'Dibuat',
    width: 140,
    render: (_v, row) => formatDate(row.created_at),
  },
]

export default function CmsPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Article>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/cms/articles/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Article>
      title="Artikel & Konten"
      addLabel="Tulis Artikel"
      onAdd={() => navigate('/cms/articles/new')}
      queryKey="cms-articles"
      fetcher={fetchArticles}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/cms/articles/${row.id}/edit`)}
      searchPlaceholder="Cari artikel..."
      exportFilename="cms-articles"
      emptyTitle="Belum ada artikel"
      emptyDescription="Tulis artikel pertama untuk website."
      helpTitle="Artikel & Konten"
      helpText="Kelola artikel, halaman statis, dan konten website dari sini."
      deleteConfig={{
        onDelete: (row) => cmsService.deleteArticle(row.id),
        dialogTitle: 'Hapus Artikel?',
        dialogBody: (row) => `"${row.title ?? 'Artikel ini'}" akan dihapus secara permanen.`,
        successMessage: (row) => `"${row.title ?? 'Artikel'}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus artikel',
      }}
    />
  )
}
