import { useParams, useNavigate } from 'react-router-dom'
import { Receipt, Trash2 } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { payableService } from '@/services/payable.service'
import { toast } from '@/widgets/Toast/Toast'
import { useDeleteConfirmModal } from '@/widgets/Modals/DeleteConfirmModal'

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  pending:   { label: 'Menunggu',  bg: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  approved:  { label: 'Disetujui', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  paid:      { label: 'Lunas',     bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  cancelled: { label: 'Dibatalkan', bg: 'var(--color-error-light)',  color: 'var(--color-error-dark)' },
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

export default function PayableDetailPage() {
  const { payableId } = useParams<{ payableId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const confirmDelete = useDeleteConfirmModal()

  const { data: payable, isLoading } = useQuery({
    queryKey: ['payable', payableId],
    queryFn: () => payableService.getById(payableId!),
    enabled: Boolean(payableId),
  })

  const p = payable as any

  function invalidate() {
    queryClient.invalidateQueries({ queryKey: ['payable', payableId] })
    queryClient.invalidateQueries({ queryKey: ['finance/payables'] })
  }

  const approveMutation = useMutation({
    mutationFn: () => payableService.approve(payableId!),
    onSuccess: () => { toast.success('Tagihan berhasil disetujui'); invalidate() },
    onError: () => toast.error('Gagal menyetujui tagihan'),
  })

  const markPaidMutation = useMutation({
    mutationFn: () => payableService.markAsPaid(payableId!),
    onSuccess: () => { toast.success('Tagihan ditandai lunas'); invalidate() },
    onError: () => toast.error('Gagal menandai lunas'),
  })

  const cancelMutation = useMutation({
    mutationFn: () => payableService.cancel(payableId!),
    onSuccess: () => { toast.success('Tagihan berhasil dibatalkan'); invalidate() },
    onError: () => toast.error('Gagal membatalkan tagihan'),
  })

  const status: string = p?.status ?? ''
  const statusCfg = STATUS_CONFIG[status] || STATUS_CONFIG.pending

  const actions: DetailPageAction[] = [
    ...(status === 'pending' ? [{
      label: 'Setujui',
      onClick: () => approveMutation.mutate(),
      variant: 'primary' as const,
    }] : []),
    ...(status === 'approved' ? [{
      label: 'Tandai Lunas',
      onClick: () => markPaidMutation.mutate(),
      variant: 'success' as const,
    }] : []),
    ...(status !== 'cancelled' && status !== 'paid' ? [{
      label: 'Batalkan',
      onClick: () => cancelMutation.mutate(),
      variant: 'danger' as const,
    }] : []),
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: () => confirmDelete('Hapus Payable', 'Yakin ingin menghapus payable ini?', async () => {
        await payableService.delete(payableId!)
        toast.success('Payable berhasil dihapus')
        navigate('/finance/payables')
      }),
      variant: 'danger' as const,
    },
  ]

  const detailContent = (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 'var(--space-3)' }}>
      {[
        { label: 'Judul/Deskripsi', value: p?.description || p?.title || '—' },
        { label: 'Jenis', value: p?.type || '—' },
        { label: 'Jumlah', value: typeof p?.amount === 'number' ? formatIDR(p.amount) : '—' },
        { label: 'Batch', value: p?.batch_name || '—' },
        { label: 'Tanggal Jatuh Tempo', value: formatDate(p?.due_date) },
        { label: 'Dibuat', value: formatDate(p?.created_at) },
      ].map(({ label, value }) => (
        <div key={label} style={{
          padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
        }}>
          <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>{label}</div>
          <div style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>{value}</div>
        </div>
      ))}
      <div style={{
        padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
      }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Status</div>
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: statusCfg.bg, color: statusCfg.color,
        }}>
          {statusCfg.label}
        </span>
      </div>
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/finance/payables')}
      icon={<Receipt size={20} />}
      title={isLoading ? 'Memuat...' : (p?.description || p?.title || 'Tagihan')}
      code={p?.id ? p.id.substring(0, 8).toUpperCase() : undefined}
      badges={
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: statusCfg.bg, color: statusCfg.color,
        }}>
          {statusCfg.label}
        </span>
      }
      actions={actions}
      helpTitle="Tagihan"
      helpText="Kelola tagihan keuangan seperti komisi fasilitator, biaya operasional, atau tagihan lainnya."
      sections={[
        {
          id: 'info',
          label: 'Informasi Tagihan',
          icon: <Receipt size={14} />,
          tabs: [{ id: 'detail', label: 'Detail', content: detailContent }],
        },
      ]}
    />
  )
}
