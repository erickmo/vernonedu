import { FolderKanban } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef } from '@/widgets/DataTable/DataTable'
import { apiClient } from '@/services/api.client'
import { buildQueryString } from '@/services/createEntityService'
import type { ListParams } from '@/services/createEntityService'

interface Project {
  id: string
  name: string
  status?: string
  start_date?: string
  end_date?: string
  budget?: number
  [key: string]: unknown
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:      { label: 'Aktif',      bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  completed:   { label: 'Selesai',    bg: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  on_hold:     { label: 'Ditunda',    bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  cancelled:   { label: 'Dibatalkan', bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
  pending:     { label: 'Menunggu',   bg: 'var(--color-surface-alt)',   color: 'var(--color-text-tertiary)' },
}

function formatIDR(amount: number): string {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency', currency: 'IDR', minimumFractionDigits: 0,
  }).format(amount)
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  }).format(new Date(dateStr))
}

const columns: ColumnDef<Project>[] = [
  {
    key: 'name',
    header: 'Nama Proyek',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <FolderKanban size={16} />
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.name || '—'}
        </div>
      </div>
    ),
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const cfg = STATUS_CONFIG[row.status ?? ''] || STATUS_CONFIG.pending
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
    key: 'start_date',
    header: 'Tanggal Mulai',
    sortable: true,
    width: 140,
    render: (_v, row) => formatDate(row.start_date),
  },
  {
    key: 'end_date',
    header: 'Tanggal Selesai',
    sortable: true,
    width: 140,
    render: (_v, row) => formatDate(row.end_date),
  },
  {
    key: 'budget',
    header: 'Anggaran',
    sortable: true,
    width: 160,
    align: 'right',
    render: (_v, row) => (
      <span style={{ fontWeight: 600 }}>
        {row.budget ? formatIDR(row.budget) : '—'}
      </span>
    ),
  },
]

export default function ProjectListPage() {
  return (
    <ListPageTemplate<Project>
      title="Proyek"
      queryKey="projects"
      fetcher={async (params: ListParams) => {
        const data = await apiClient.get<any>(`/projects${buildQueryString(params)}`)
        const items = Array.isArray(data) ? data : ((data as any)?.data ?? [])
        return { items, total: items.length, limit: 9999, offset: 0 }
      }}
      columns={columns}
      hidePagination
      searchPlaceholder="Cari proyek..."
      exportFilename="proyek"
      emptyTitle="Belum ada proyek"
      emptyDescription="Buat proyek untuk event atau inisiatif non-recurring."
      helpTitle="Proyek"
      helpText="Proyek adalah event atau inisiatif satu kali yang bisa berkolaborasi dengan partner dan memiliki anggaran tersendiri."
    />
  )
}
