import { useNavigate } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { marketingService } from '@/services/marketing.service'

interface SocialPost {
  id: string
  platform?: string
  caption?: string
  content?: string
  status?: string
  scheduled_at?: string
  publish_date?: string
  [key: string]: unknown
}

const PLATFORM_COLORS: Record<string, { bg: string; color: string }> = {
  instagram: { bg: '#fce4ec', color: '#c2185b' },
  facebook:  { bg: '#e3f2fd', color: '#1565c0' },
  tiktok:    { bg: '#212121', color: '#ffffff' },
  youtube:   { bg: '#ffebee', color: '#b71c1c' },
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  draft:     { label: 'Draft',     bg: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  published: { label: 'Published', bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  scheduled: { label: 'Scheduled', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
}

const columns: ColumnDef<SocialPost>[] = [
  {
    key: 'platform',
    header: 'Platform',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const platform = (row.platform || '').toLowerCase()
      const cfg = PLATFORM_COLORS[platform]
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg?.bg ?? 'var(--color-surface-alt)',
          color: cfg?.color ?? 'var(--color-text-tertiary)',
          textTransform: 'capitalize',
        }}>
          {row.platform || '—'}
        </span>
      )
    },
  },
  {
    key: 'caption',
    header: 'Konten',
    render: (_v, row) => {
      const text = (row.caption || row.content || '') as string
      return (
        <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
          {text.length > 80 ? `${text.slice(0, 80)}…` : text || '—'}
        </div>
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
    key: 'scheduled_at',
    header: 'Tanggal',
    width: 140,
    render: (_v, row) => {
      const dateStr = row.scheduled_at || row.publish_date
      if (!dateStr) return '—'
      return new Date(dateStr as string).toLocaleDateString('id-ID', {
        day: '2-digit', month: 'short', year: 'numeric',
      })
    },
  },
]

export default function SocialPostListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<SocialPost>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/marketing/social/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<SocialPost>
      title="Konten Sosial Media"
      addLabel="Tambah Konten"
      onAdd={() => navigate('/marketing/social/new')}
      queryKey="marketing-posts"
      fetcher={async (params) => {
        const raw = await marketingService.listPosts(params)
        const items = Array.isArray(raw) ? raw : (raw as any)?.items ?? []
        return { items, total: items.length, limit: 9999, offset: 0 }
      }}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/marketing/social/${row.id}/edit`)}
      searchPlaceholder="Cari konten sosial media..."
      exportFilename="social-posts"
      emptyTitle="Belum ada konten"
      emptyDescription="Buat konten sosial media untuk promosi kursus."
      deleteConfig={{
        onDelete: (row) => marketingService.deletePost(row.id),
        dialogTitle: 'Hapus Konten?',
        dialogBody: (row) => `Konten dari platform ${row.platform || 'ini'} akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: () => 'Konten berhasil dihapus',
        errorMessage: 'Gagal menghapus konten',
      }}
    />
  )
}
