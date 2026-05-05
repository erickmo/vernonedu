import { useParams, useNavigate } from 'react-router-dom'
import { BookOpen, Pencil, CheckCircle, XCircle, Archive, Trash2 } from 'lucide-react'
import { useQuery, useQueryClient, useMutation } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { enrollmentService } from '@/services/enrollment.service'
import { toast } from '@/widgets/Toast/Toast'
import { useDeleteConfirmModal } from '@/widgets/Modals/DeleteConfirmModal'

function formatDate(dateStr?: string | null) {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(dateStr))
}

function formatCurrency(amount?: number | null) {
  if (amount == null) return '—'
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(amount)
}

const ENROLLMENT_STATUS_COLORS: Record<string, { background: string; color: string }> = {
  active:    { background: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  completed: { background: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  withdrawn: { background: 'var(--color-danger-light)',  color: 'var(--color-danger-dark)' },
}

const PAYMENT_STATUS_COLORS: Record<string, { background: string; color: string }> = {
  paid:    { background: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  partial: { background: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  pending: { background: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  overdue: { background: 'var(--color-danger-light)',  color: 'var(--color-danger-dark)' },
}

function PillBadge({ label, styleMap, status }: { label: string; styleMap: Record<string, { background: string; color: string }>; status?: string }) {
  const s = styleMap[status ?? ''] ?? { background: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }
  return (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600, ...s,
    }}>
      {label}
    </span>
  )
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

export default function EnrollmentDetailPage() {
  const { enrollmentId } = useParams<{ enrollmentId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const confirmDelete = useDeleteConfirmModal()

  const { data } = useQuery({
    queryKey: ['enrollment', enrollmentId],
    queryFn: () => enrollmentService.getById(enrollmentId!),
  })

  const enrollment = data as any

  const statusMutation = useMutation({
    mutationFn: (status: string) => enrollmentService.updateStatus(enrollmentId!, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['enrollment', enrollmentId] })
      toast.success('Status pendaftaran berhasil diperbarui')
    },
    onError: (err: any) => {
      toast.error(err instanceof Error ? err.message : 'Gagal memperbarui status')
    },
  })

  const currentStatus = enrollment?.status as string | undefined

  const actions: DetailPageAction[] = [
    {
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/enrollments/${enrollmentId}/edit`),
      variant: 'default',
    },
    ...(currentStatus !== 'active' ? [{
      label: 'Aktifkan',
      icon: <CheckCircle size={14} />,
      onClick: () => statusMutation.mutate('active'),
      variant: 'success' as const,
    }] : []),
    ...(currentStatus !== 'completed' ? [{
      label: 'Selesaikan',
      icon: <Archive size={14} />,
      onClick: () => statusMutation.mutate('completed'),
      variant: 'primary' as const,
    }] : []),
    ...(currentStatus !== 'withdrawn' ? [{
      label: 'Withdraw',
      icon: <XCircle size={14} />,
      onClick: () => statusMutation.mutate('withdrawn'),
      variant: 'danger' as const,
    }] : []),
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: () => confirmDelete('Hapus Enrollment', 'Yakin ingin menghapus enrollment ini?', async () => {
        await enrollmentService.delete(enrollmentId!)
        toast.success('Enrollment berhasil dihapus')
        navigate('/enrollments')
      }),
      variant: 'danger' as const,
    },
  ]

  const detailContent = (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 'var(--space-3)' }}>
      <InfoCard label="Siswa">
        {enrollment?.student_name || enrollment?.student?.name || '—'}
      </InfoCard>
      <InfoCard label="Batch Kursus">
        {enrollment?.batch_name || enrollment?.batch?.name || '—'}
      </InfoCard>
      <InfoCard label="Kursus">
        {enrollment?.course_name || '—'}
      </InfoCard>
      <InfoCard label="Metode Pembayaran">
        {enrollment?.payment_method || '—'}
      </InfoCard>
      <InfoCard label="Status Pendaftaran">
        <PillBadge
          label={currentStatus ?? '—'}
          styleMap={ENROLLMENT_STATUS_COLORS}
          status={currentStatus}
        />
      </InfoCard>
      <InfoCard label="Status Pembayaran">
        <PillBadge
          label={enrollment?.payment_status ?? '—'}
          styleMap={PAYMENT_STATUS_COLORS}
          status={enrollment?.payment_status}
        />
      </InfoCard>
      <InfoCard label="Tanggal Daftar">
        {formatDate(enrollment?.created_at)}
      </InfoCard>
      <InfoCard label="Harga">
        {formatCurrency(enrollment?.price)}
      </InfoCard>
    </div>
  )

  const studentName = enrollment?.student_name || enrollment?.student?.name

  return (
    <DetailPageTemplate
      onBack={() => navigate('/enrollments')}
      icon={<BookOpen size={20} />}
      title={studentName || 'Pendaftaran'}
      code={enrollment?.id?.substring(0, 8)?.toUpperCase()}
      badges={
        <>
          <PillBadge
            label={currentStatus ?? '—'}
            styleMap={ENROLLMENT_STATUS_COLORS}
            status={currentStatus}
          />
          <PillBadge
            label={enrollment?.payment_status ?? '—'}
            styleMap={PAYMENT_STATUS_COLORS}
            status={enrollment?.payment_status}
          />
        </>
      }
      actions={actions}
      helpTitle="Pendaftaran"
      helpText="Kelola status pendaftaran dan pembayaran siswa."
      sections={[
        {
          id: 'info',
          label: 'Informasi Pendaftaran',
          icon: <BookOpen size={14} />,
          tabs: [{ id: 'detail', label: 'Detail', content: detailContent }],
        },
      ]}
    />
  )
}
