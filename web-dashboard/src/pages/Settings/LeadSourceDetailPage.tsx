import { useParams, useNavigate } from 'react-router-dom'
import { Tag, Pencil, Trash2 } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { leadSourceService } from '@/services/lead-source.service'
import { toast } from '@/widgets/Toast/Toast'
import { useDeleteConfirmModal } from '@/widgets/Modals/DeleteConfirmModal'

function InfoCard({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{
      padding: 'var(--space-4)', border: '1px solid var(--color-border)',
      borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)',
    }}>
      <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>
        {label}
      </div>
      <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{children}</div>
    </div>
  )
}

export default function LeadSourceDetailPage() {
  const { sourceId } = useParams<{ sourceId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const confirmDelete = useDeleteConfirmModal()

  const { data: source } = useQuery({
    queryKey: ['lead-source', sourceId],
    queryFn: () => leadSourceService.getById(sourceId!),
  })

  const actions: DetailPageAction[] = [
    {
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/settings/lead-sources/${sourceId}/edit`),
      variant: 'default',
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: () => confirmDelete(
        'Hapus Sumber Lead?',
        `"${source?.name}" akan dihapus. Lead yang sudah menggunakan sumber ini tidak akan terpengaruh.`,
        async () => {
          await leadSourceService.delete(sourceId!)
          queryClient.invalidateQueries({ queryKey: ['lead-sources'] })
          toast.success(`Sumber "${source?.name}" berhasil dihapus`)
          navigate('/settings/lead-sources')
        },
      ),
      variant: 'danger' as const,
    },
  ]

  const detailContent = (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 'var(--space-3)' }}>
      <InfoCard label="Nama Sumber">{source?.name ?? '—'}</InfoCard>
      <InfoCard label="Status">
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: source?.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
          color: source?.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
        }}>
          {source?.is_active ? 'Aktif' : 'Nonaktif'}
        </span>
      </InfoCard>
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/settings/lead-sources')}
      icon={<Tag size={20} />}
      title={source?.name ?? 'Sumber Lead'}
      badges={
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: source?.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
          color: source?.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
        }}>
          {source?.is_active ? 'Aktif' : 'Nonaktif'}
        </span>
      }
      actions={actions}
      helpTitle="Sumber Lead"
      helpText="Sumber lead adalah kategori asal prospek (contoh: Referral, Website)."
      sections={[
        {
          id: 'info',
          label: 'Informasi',
          icon: <Tag size={14} />,
          tabs: [{ id: 'detail', label: 'Detail', content: detailContent }],
        },
      ]}
    />
  )
}
