import { useNavigate } from 'react-router-dom'
import { FileText, Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { cmsService } from '@/services/cms.service'

interface Article {
  id: string
  title: string
  category?: string
  status?: string
  author?: string
  author_name?: string
  published_at?: string
  created_at?: string
  [key: string]: unknown
}

const CATEGORY_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  tutorial:     { label: 'Tutorial',      bg: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  news:         { label: 'News',          bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  announcement: { label: 'Announcement', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  other:        { label: 'Other',         bg: 'var(--color-surface-alt)',   color: 'var(--color-text-tertiary)' },
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  draft:    { label: 'Draft',     bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  published:{ label: 'Published', bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  archived: { label: 'Archived',  bg: 'var(--color-danger-light)',  color: 'var(--color-danger-dark)' },
}

const columns: ColumnDef<Article>[] = [
  {
    key: 'title',
    header: 'Judul',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <FileText size={16} />
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.title || '—'}
        </div>
      </div>
    ),
  },
  {
    key: 'category',
    header: 'Kategori',
    width: 150,
    align: 'center',
    render: (_v, row) => {
      if (!row.category) return '—'
      const cfg = CATEGORY_CONFIG[row.category] || CATEGORY_CONFIG.other
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      )
    },
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const status = row.status || 'draft'
      const cfg = STATUS_CONFIG[status] || STATUS_CONFIG.draft
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      )
    },
  },
  {
    key: 'author',
    header: 'Penulis',
    width: 180,
    render: (_v, row) => (
      <span>{row.author_name || row.author || '—'}</span>
    ),
  },
  {
    key: 'published_at',
    header: 'Tanggal Terbit',
    width: 160,
    render: (_v, row) => {
      const date = row.published_at || row.created_at
      if (!date) return '—'
      return new Date(date as string).toLocaleDateString('id-ID', {
        day: '2-digit', month: 'short', year: 'numeric',
      })
    },
  },
]

export default function ArticleListPage() {
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
      title="Artikel"
      addLabel="Tulis Artikel"
      onAdd={() => navigate('/cms/articles/new')}
      queryKey="cms-articles"
      fetcher={async (params) => {
        const raw = await cmsService.listArticles(params)
        const items = Array.isArray(raw) ? raw : (raw as any)?.items ?? []
        return { items, total: items.length, limit: 9999, offset: 0 }
      }}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari artikel..."
      exportFilename="articles"
      emptyTitle="Belum ada artikel"
      emptyDescription="Tulis artikel untuk website publik VernonEdu."
      helpTitle="Artikel"
      helpText="Kelola konten artikel yang ditampilkan di website publik. Artikel dapat berupa berita, tutorial, atau pengumuman."
      deleteConfig={{
        onDelete: (row) => cmsService.deleteArticle(row.id),
        dialogTitle: 'Hapus Artikel?',
        dialogBody: (row) => `"${row.title}" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `Artikel "${row.title}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus artikel',
      }}
    />
  )
}
