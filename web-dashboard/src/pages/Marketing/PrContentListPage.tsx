import { useNavigate } from 'react-router-dom'
import { Newspaper, Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { marketingService } from '@/services/marketing.service'

interface PrContent {
  id: string
  title?: string
  type?: string
  status?: string
  publish_date?: string
  created_at?: string
  [key: string]: unknown
}

const TYPE_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  press_release: { label: 'Press Release', bg: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  article:       { label: 'Artikel',       bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  blog:          { label: 'Blog',          bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  other:         { label: 'Lainnya',       bg: 'var(--color-surface-alt)',   color: 'var(--color-text-tertiary)' },
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  draft:    { label: 'Draft',    bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  published:{ label: 'Published',bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  archived: { label: 'Archived', bg: 'var(--color-danger-light)',  color: 'var(--color-danger-dark)' },
}

const columns: ColumnDef<PrContent>[] = [
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
          <Newspaper size={16} />
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.title || '—'}
        </div>
      </div>
    ),
  },
  {
    key: 'type',
    header: 'Jenis',
    width: 140,
    align: 'center',
    render: (_v, row) => {
      const type = row.type || 'other'
      const cfg = TYPE_CONFIG[type] || TYPE_CONFIG.other
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
    key: 'publish_date',
    header: 'Tanggal',
    width: 140,
    render: (_v, row) => {
      const dateStr = row.publish_date || row.created_at
      if (!dateStr) return '—'
      return new Date(dateStr as string).toLocaleDateString('id-ID', {
        day: '2-digit', month: 'short', year: 'numeric',
      })
    },
  },
]

export default function PrContentListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<PrContent>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/marketing/pr/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<PrContent>
      title="Konten PR & Artikel"
      addLabel="Tambah Konten"
      onAdd={() => navigate('/marketing/pr/new')}
      queryKey="marketing-pr"
      fetcher={async (params) => {
        const raw = await marketingService.listPr(params)
        const items = Array.isArray(raw) ? raw : (raw as any)?.items ?? []
        return { items, total: items.length, limit: 9999, offset: 0 }
      }}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/marketing/pr/${row.id}/edit`)}
      searchPlaceholder="Cari artikel PR..."
      exportFilename="pr-content"
      emptyTitle="Belum ada konten PR"
      emptyDescription="Tambahkan konten PR dan artikel untuk komunikasi publik."
      deleteConfig={{
        onDelete: (row) => marketingService.deletePr(row.id),
        dialogTitle: 'Hapus Konten PR?',
        dialogBody: (row) => `"${row.title || 'Konten ini'}" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `Konten "${row.title || ''}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus konten PR',
      }}
    />
  )
}
