import { useNavigate } from 'react-router-dom'
import { Pencil, Megaphone } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { marketingService } from '@/services/marketing.service'
import type { ListParams } from '@/services/createEntityService'
import type { PaginatedResponse } from '@/types/api.types'

interface MarketingPost {
  id: string
  title?: string
  platform?: string
  status?: string
  content_url?: string
  scheduled_at?: number
  created_at?: number
  [key: string]: unknown
}

function formatDate(ts: number | undefined): string {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  }).format(new Date(ts * 1000))
}

async function fetchPosts(params: ListParams): Promise<PaginatedResponse<MarketingPost>> {
  const raw = await marketingService.listPosts(params)
  const items: MarketingPost[] = Array.isArray(raw?.items) ? raw.items : (Array.isArray(raw) ? raw : [])
  return { items, total: raw?.total ?? items.length, offset: 0, limit: params.limit ?? 100 }
}

const columns: ColumnDef<MarketingPost>[] = [
  {
    key: 'platform',
    header: 'Platform',
    width: 120,
    render: (_v, row) => (
      <span style={{
        display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
        fontSize: 'var(--font-xs)', fontWeight: 600,
        background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
      }}>
        {row.platform ?? '—'}
      </span>
    ),
  },
  {
    key: 'title',
    header: 'Judul / Konten',
    sortable: true,
    render: (_v, row) => (
      <div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.title ?? '(Tanpa judul)'}
        </div>
        {row.content_url && (
          <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
            {row.content_url.length > 60 ? row.content_url.slice(0, 60) + '...' : row.content_url}
          </div>
        )}
      </div>
    ),
  },
  {
    key: 'status',
    header: 'Status',
    width: 110,
    align: 'center',
    render: (_v, row) => {
      const isDraft = row.status === 'draft'
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: isDraft ? 'var(--color-surface-alt)' : 'var(--color-success-light)',
          color: isDraft ? 'var(--color-text-tertiary)' : 'var(--color-success-dark)',
        }}>
          {row.status ?? '—'}
        </span>
      )
    },
  },
  {
    key: 'scheduled_at',
    header: 'Jadwal Tayang',
    width: 140,
    render: (_v, row) => formatDate(row.scheduled_at),
  },
]

export default function MarketingPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<MarketingPost>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/marketing/social/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<MarketingPost>
      title="Konten Marketing"
      addLabel="Tambah Konten"
      onAdd={() => navigate('/marketing/social/new')}
      queryKey="marketing-posts"
      fetcher={fetchPosts}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/marketing/social/${row.id}/edit`)}
      searchPlaceholder="Cari konten..."
      exportFilename="marketing-posts"
      emptyTitle="Belum ada konten marketing"
      emptyDescription="Buat konten marketing pertama."
      helpTitle="Konten Marketing"
      helpText="Kelola social posts, PR content, dan referral partners dari halaman ini."
      deleteConfig={{
        onDelete: (row) => marketingService.deletePost(row.id),
        dialogTitle: 'Hapus Konten?',
        dialogBody: (row) => `"${row.title ?? 'Konten ini'}" akan dihapus secara permanen.`,
        successMessage: (row) => `"${row.title ?? 'Konten'}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus konten',
      }}
      actions={
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Megaphone size={16} style={{ color: 'var(--color-text-secondary)' }} />
        </div>
      }
    />
  )
}
