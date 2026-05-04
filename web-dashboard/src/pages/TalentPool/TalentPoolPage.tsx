import { useQueryClient } from '@tanstack/react-query'
import { UserCheck, RefreshCw } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { talentPoolService } from '@/services/talentpool.service'
import { toast } from '@/widgets/Toast/Toast'

interface TalentPoolEntry {
  id: string
  student_name: string
  department_name?: string
  status?: string
  pipeline_stage?: string
  [key: string]: unknown
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:     { label: 'Aktif',       bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  graduated:  { label: 'Lulus',       bg: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  on_hold:    { label: 'Ditunda',     bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  rejected:   { label: 'Ditolak',     bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
  pending:    { label: 'Menunggu',    bg: 'var(--color-surface-alt)',   color: 'var(--color-text-tertiary)' },
}

const PIPELINE_LABELS: Record<string, string> = {
  learning: 'Pembelajaran',
  internship: 'Magang',
  recommendation: 'Rekomendasi',
  test: 'Tes Karakter',
  talent_pool: 'Talent Pool',
  hired: 'Diterima',
}

const columns: ColumnDef<TalentPoolEntry>[] = [
  {
    key: 'student_name',
    header: 'Nama',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: '50%',
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0, fontSize: 'var(--font-sm)', fontWeight: 600,
        }}>
          {row.student_name?.charAt(0)?.toUpperCase() || '?'}
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.student_name || '—'}
        </div>
      </div>
    ),
  },
  {
    key: 'department_name',
    header: 'Departemen',
    sortable: true,
    width: 160,
    render: (_v, row) => row.department_name || '—',
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
    key: 'pipeline_stage',
    header: 'Tahap Pipeline',
    width: 160,
    render: (_v, row) => PIPELINE_LABELS[row.pipeline_stage ?? ''] || row.pipeline_stage || '—',
  },
]

export default function TalentPoolPage() {
  const queryClient = useQueryClient()

  const rowActions: RowActionDef<TalentPoolEntry>[] = [
    {
      key: 'updateStatus',
      label: 'Update Status',
      icon: <RefreshCw size={14} />,
      onClick: async (row) => {
        try {
          const nextStatus = row.status === 'active' ? 'graduated'
            : row.status === 'pending' ? 'active'
            : 'active'
          await talentPoolService.updateStatus(row.id, nextStatus)
          await queryClient.invalidateQueries({ queryKey: ['talentpool'] })
          toast.success(`Status ${row.student_name} diperbarui`)
        } catch {
          toast.error('Gagal memperbarui status')
        }
      },
      visible: (row) => row.status !== 'rejected',
    },
    {
      key: 'approve',
      label: 'Terima',
      icon: <UserCheck size={14} />,
      onClick: async (row) => {
        try {
          await talentPoolService.updateStatus(row.id, 'active')
          await queryClient.invalidateQueries({ queryKey: ['talentpool'] })
          toast.success(`${row.student_name} diterima ke talent pool`)
        } catch {
          toast.error('Gagal memperbarui status')
        }
      },
      visible: (row) => row.status === 'pending',
    },
  ]

  return (
    <ListPageTemplate<TalentPoolEntry>
      title="Talent Pool"
      queryKey="talentpool"
      fetcher={(params) => talentPoolService.list(params)}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari talent..."
      exportFilename="talent-pool"
      emptyTitle="Belum ada talent"
      emptyDescription="Talent pool akan terisi dari pipeline Program Karir yang telah menyelesaikan tahap seleksi."
      helpTitle="Talent Pool"
      helpText="Talent Pool berisi kandidat dari Program Karir yang telah menyelesaikan tahap pembelajaran, magang, dan tes. Mereka siap untuk direkomendasikan ke partner."
    />
  )
}
