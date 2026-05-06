import { useParams, useNavigate } from 'react-router-dom'
import { Briefcase, Pencil, Trash2, ToggleLeft, ToggleRight } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { jobVacancyService } from '@/services/jobvacancy.service'
import { toast } from '@/widgets/Toast/Toast'
import { useDeleteConfirmModal } from '@/widgets/Modals/DeleteConfirmModal'

const TYPE_LABELS: Record<string, string> = {
  'full-time': 'Full-time',
  'part-time': 'Part-time',
  internship: 'Magang',
  contract: 'Kontrak',
}

const EXPERIENCE_LABELS: Record<string, string> = {
  junior: 'Junior',
  mid: 'Mid-level',
  senior: 'Senior',
}

const STATUS_COLORS: Record<string, { bg: string; color: string }> = {
  open:   { bg: 'var(--color-success-light)',  color: 'var(--color-success-dark)' },
  closed: { bg: 'var(--color-surface-alt)',     color: 'var(--color-text-tertiary)' },
  draft:  { bg: 'var(--color-warning-light)',   color: 'var(--color-warning-dark)' },
}

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

function formatSalary(val?: number | null): string {
  if (!val) return '—'
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
}

export default function TalentPoolLowonganDetailPage() {
  const { vacancyId } = useParams<{ vacancyId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const confirmDelete = useDeleteConfirmModal()

  const { data: vacancy } = useQuery({
    queryKey: ['job-vacancy', vacancyId],
    queryFn: () => jobVacancyService.getById(vacancyId!),
  })

  const statusStyle = STATUS_COLORS[vacancy?.status ?? ''] ?? STATUS_COLORS.draft

  const actions: DetailPageAction[] = [
    {
      label: vacancy?.status === 'open' ? 'Tutup Lowongan' : 'Buka Lowongan',
      icon: vacancy?.status === 'open' ? <ToggleLeft size={14} /> : <ToggleRight size={14} />,
      onClick: async () => {
        const newStatus = vacancy?.status === 'open' ? 'closed' : 'open'
        await jobVacancyService.changeStatus(vacancyId!, newStatus)
        queryClient.invalidateQueries({ queryKey: ['job-vacancy', vacancyId] })
        queryClient.invalidateQueries({ queryKey: ['talentpool-lowongan'] })
        toast.success(`Status lowongan diubah ke ${newStatus}`)
      },
      variant: 'default',
    },
    {
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/talentpool/lowongan/${vacancyId}/edit`),
      variant: 'default',
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: () => confirmDelete(
        'Hapus Lowongan?',
        `"${vacancy?.title}" akan dihapus permanen.`,
        async () => {
          await jobVacancyService.delete(vacancyId!)
          queryClient.invalidateQueries({ queryKey: ['talentpool-lowongan'] })
          toast.success('Lowongan berhasil dihapus')
          navigate('/talentpool/lowongan')
        },
      ),
      variant: 'danger' as const,
    },
  ]

  const infoContent = (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 'var(--space-3)', marginBottom: 'var(--space-3)' }}>
        <InfoCard label="Jenis Pekerjaan">{TYPE_LABELS[vacancy?.type ?? ''] ?? vacancy?.type ?? '—'}</InfoCard>
        <InfoCard label="Level Pengalaman">{EXPERIENCE_LABELS[vacancy?.experience_level ?? ''] ?? vacancy?.experience_level ?? '—'}</InfoCard>
        <InfoCard label="Lokasi">{vacancy?.location || '—'}</InfoCard>
        <InfoCard label="Kuota">{vacancy?.slots ? `${vacancy.slots} posisi` : '—'}</InfoCard>
        <InfoCard label="Gaji Minimum">{formatSalary(vacancy?.min_salary)}</InfoCard>
        <InfoCard label="Gaji Maksimum">{formatSalary(vacancy?.max_salary)}</InfoCard>
        <InfoCard label="Batas Waktu">
          {vacancy?.deadline ? new Date(vacancy.deadline * 1000).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) : '—'}
        </InfoCard>
        <InfoCard label="Dibuat">
          {vacancy?.created_at ? new Date(vacancy.created_at * 1000).toLocaleDateString('id-ID') : '—'}
        </InfoCard>
      </div>
      {vacancy?.description && (
        <div style={{
          padding: 'var(--space-4)', border: '1px solid var(--color-border)',
          borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)',
          marginBottom: 'var(--space-3)',
        }}>
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 8 }}>Deskripsi</div>
          <p style={{ fontSize: 'var(--font-base)', lineHeight: 1.6, margin: 0 }}>{vacancy.description}</p>
        </div>
      )}
      {vacancy?.required_skills?.length > 0 && (
        <div style={{
          padding: 'var(--space-4)', border: '1px solid var(--color-border)',
          borderRadius: 'var(--radius-lg)', background: 'var(--color-surface-elevated)',
        }}>
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 8 }}>Skill Dibutuhkan</div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {(vacancy.required_skills as string[]).map((skill: string) => (
              <span key={skill} style={{
                padding: '2px 10px', borderRadius: 'var(--radius-full)',
                background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
                fontSize: 'var(--font-xs)', fontWeight: 600,
              }}>{skill}</span>
            ))}
          </div>
        </div>
      )}
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/talentpool/lowongan')}
      icon={<Briefcase size={20} />}
      title={vacancy?.title ?? 'Lowongan'}
      badges={
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: statusStyle.bg, color: statusStyle.color,
        }}>
          {vacancy?.status === 'open' ? 'Buka' : vacancy?.status === 'draft' ? 'Draft' : 'Tutup'}
        </span>
      }
      actions={actions}
      helpTitle="Lowongan Kerja"
      helpText="Detail lowongan pekerjaan dari perusahaan partner untuk kandidat Talent Pool."
      sections={[
        {
          id: 'info',
          label: 'Informasi',
          icon: <Briefcase size={14} />,
          tabs: [{ id: 'detail', label: 'Detail', content: infoContent }],
        },
      ]}
    />
  )
}
