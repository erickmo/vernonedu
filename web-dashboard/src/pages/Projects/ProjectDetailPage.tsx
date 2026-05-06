import { useParams, useNavigate } from 'react-router-dom'
import { FolderOpen, Pencil, Trash2 } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { projectService } from '@/services/project.service'
import { toast } from '@/widgets/Toast/Toast'

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:    { label: 'Aktif',      bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  completed: { label: 'Selesai',    bg: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  cancelled: { label: 'Dibatalkan', bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
  planned:   { label: 'Direncanakan', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
}

function formatDate(dateStr?: string): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  }).format(new Date(dateStr))
}

function formatIDR(amount?: number): string {
  if (!amount) return '—'
  return new Intl.NumberFormat('id-ID', {
    style: 'currency', currency: 'IDR', minimumFractionDigits: 0,
  }).format(amount)
}

export default function ProjectDetailPage() {
  const { projectId } = useParams<{ projectId: string }>()
  const navigate = useNavigate()

  const { data: project, isLoading } = useQuery({
    queryKey: ['project', projectId],
    queryFn: () => projectService.getById(projectId!),
  })

  const p = project as any

  const statusCfg = STATUS_CONFIG[p?.status ?? ''] ?? STATUS_CONFIG.planned

  async function handleDelete() {
    if (!window.confirm('Yakin ingin menghapus proyek ini?')) return
    try {
      await projectService.delete(projectId!)
      toast.success('Proyek berhasil dihapus')
      navigate('/projects')
    } catch {
      toast.error('Gagal menghapus proyek')
    }
  }

  const actions: DetailPageAction[] = [
    {
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/projects/${projectId}/edit`),
      variant: 'default',
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: handleDelete,
      variant: 'danger',
    },
  ]

  const badges = p?.status ? (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600,
      background: statusCfg.bg, color: statusCfg.color,
    }}>
      {statusCfg.label}
    </span>
  ) : undefined

  const detailContent = (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 'var(--space-3)' }}>
      <div style={{ padding: 'var(--space-4)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)' }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Nama</div>
        <div style={{ fontWeight: 600 }}>{p?.name || '—'}</div>
      </div>

      <div style={{ padding: 'var(--space-4)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)' }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Status</div>
        <div>
          {p?.status ? (
            <span style={{
              display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-xs)', fontWeight: 600,
              background: statusCfg.bg, color: statusCfg.color,
            }}>
              {statusCfg.label}
            </span>
          ) : '—'}
        </div>
      </div>

      <div style={{ padding: 'var(--space-4)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)' }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Jenis</div>
        <div style={{ fontWeight: 600 }}>{p?.type || '—'}</div>
      </div>

      <div style={{ padding: 'var(--space-4)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)', gridColumn: 'span 2' }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Deskripsi</div>
        <div style={{ fontWeight: 600 }}>{p?.description || '—'}</div>
      </div>

      <div style={{ padding: 'var(--space-4)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)' }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Tanggal Mulai</div>
        <div style={{ fontWeight: 600 }}>{formatDate(p?.start_date)}</div>
      </div>

      <div style={{ padding: 'var(--space-4)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)' }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Tanggal Selesai</div>
        <div style={{ fontWeight: 600 }}>{formatDate(p?.end_date)}</div>
      </div>

      <div style={{ padding: 'var(--space-4)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)' }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Anggaran</div>
        <div style={{ fontWeight: 600 }}>{formatIDR(p?.budget)}</div>
      </div>

      <div style={{ padding: 'var(--space-4)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)' }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Partner</div>
        <div style={{ fontWeight: 600 }}>{p?.partner_name || '—'}</div>
      </div>
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/projects')}
      icon={<FolderOpen size={20} />}
      title={isLoading ? 'Memuat...' : (p?.name ?? 'Proyek')}
      code={p?.id?.substring(0, 8)?.toUpperCase()}
      badges={badges}
      actions={actions}
      helpTitle="Detail Proyek"
      helpText="Halaman ini menampilkan informasi lengkap proyek. Klik Edit untuk mengubah data atau Hapus untuk menghapus proyek."
      sections={[
        {
          id: 'info',
          label: 'Informasi Proyek',
          icon: <FolderOpen size={14} />,
          tabs: [{ id: 'detail', label: 'Detail', content: detailContent }],
        },
      ]}
    />
  )
}
