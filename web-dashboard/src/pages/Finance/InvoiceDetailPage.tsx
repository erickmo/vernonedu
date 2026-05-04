import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { FileText, CheckCircle, Send, XCircle, Clock, User, BookOpen, Calendar, DollarSign } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { invoiceService } from '@/services/invoice.service'
import { toast } from '@/widgets/Toast/Toast'

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  draft:     { label: 'Draft',        bg: 'var(--color-surface-alt)',      color: 'var(--color-text-tertiary)' },
  sent:      { label: 'Terkirim',     bg: 'var(--color-info-light)',       color: 'var(--color-info-dark)' },
  paid:      { label: 'Lunas',        bg: 'var(--color-success-light)',    color: 'var(--color-success-dark)' },
  overdue:   { label: 'Jatuh Tempo',  bg: 'var(--color-warning-light)',    color: 'var(--color-warning-dark)' },
  cancelled: { label: 'Dibatalkan',   bg: 'var(--color-error-light)',      color: 'var(--color-error-dark)' },
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

function formatDateTime(dateStr?: string): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(dateStr))
}

function InfoRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: React.ReactNode }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 'var(--space-3)',
      padding: 'var(--space-3) 0', borderBottom: '1px solid var(--color-border)',
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 'var(--radius-md)', flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: 'var(--color-text-tertiary)', marginTop: 2,
      }}>
        {icon}
      </div>
      <div style={{ minWidth: 0, flex: 1 }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 2 }}>{label}</div>
        <div style={{ fontWeight: 500 }}>{value}</div>
      </div>
    </div>
  )
}

export default function InvoiceDetailPage() {
  const { invoiceId } = useParams<{ invoiceId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [actionLoading, setActionLoading] = useState(false)

  const { data: invoice, isLoading } = useQuery({
    queryKey: ['finance/invoices', invoiceId],
    queryFn: () => invoiceService.getDetail(invoiceId!),
  })

  async function handleAction(action: () => Promise<unknown>, successMsg: string, errMsg: string) {
    setActionLoading(true)
    try {
      await action()
      await queryClient.invalidateQueries({ queryKey: ['finance/invoices', invoiceId] })
      toast.success(successMsg)
    } catch {
      toast.error(errMsg)
    } finally {
      setActionLoading(false)
    }
  }

  const status = invoice?.status || 'draft'
  const cfg = STATUS_CONFIG[status] || STATUS_CONFIG.draft

  const actions: DetailPageAction[] = [
    ...(status !== 'paid' && status !== 'cancelled'
      ? [{
          label: 'Tandai Lunas',
          icon: <CheckCircle size={14} />,
          onClick: () => handleAction(
            () => invoiceService.markAsPaid(invoiceId!),
            `Invoice ${invoice?.invoice_number} ditandai lunas`,
            'Gagal menandai lunas',
          ),
          variant: 'success' as const,
          disabled: actionLoading,
        }
      ] : []),
    ...(status === 'draft'
      ? [{
          label: 'Kirim',
          icon: <Send size={14} />,
          onClick: () => handleAction(
            () => invoiceService.send(invoiceId!),
            `Invoice ${invoice?.invoice_number} berhasil dikirim`,
            'Gagal mengirim invoice',
          ),
          variant: 'default' as const,
          disabled: actionLoading,
        }
      ] : []),
    ...(status !== 'cancelled'
      ? [{
          label: 'Batalkan',
          icon: <XCircle size={14} />,
          onClick: () => handleAction(
            () => invoiceService.cancel(invoiceId!, 'Dibatalkan oleh admin'),
            `Invoice ${invoice?.invoice_number} dibatalkan`,
            'Gagal membatalkan invoice',
          ),
          variant: 'danger' as const,
          disabled: actionLoading,
        }
      ] : []),
  ]

  const summaryTab = (
    <div>
      <div style={{
        padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
      }}>
        <InfoRow
          icon={<FileText size={15} />}
          label="No. Invoice"
          value={<span style={{ fontFamily: 'var(--font-mono, monospace)', fontWeight: 700 }}>{invoice?.invoice_number || '—'}</span>}
        />
        <InfoRow
          icon={<User size={15} />}
          label="Siswa"
          value={
            <div>
              <div>{invoice?.student_name || '—'}</div>
              {invoice?.student_email && (
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)' }}>
                  {invoice.student_email}
                </div>
              )}
            </div>
          }
        />
        <InfoRow
          icon={<BookOpen size={15} />}
          label="Batch"
          value={invoice?.batch_name || '—'}
        />
        <InfoRow
          icon={<DollarSign size={15} />}
          label="Jumlah"
          value={<span style={{ fontWeight: 700, fontSize: 'var(--font-lg)' }}>{formatIDR(invoice?.amount ?? 0)}</span>}
        />
        <InfoRow
          icon={<Calendar size={15} />}
          label="Tanggal Jatuh Tempo"
          value={formatDate(invoice?.due_date)}
        />
        <InfoRow
          icon={<Clock size={15} />}
          label="Dibuat"
          value={formatDateTime(invoice?.created_at)}
        />
        {invoice?.notes && (
          <div style={{
            padding: 'var(--space-3) 0',
          }}>
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 4 }}>Catatan</div>
            <div style={{
              padding: 'var(--space-3)', borderRadius: 'var(--radius-md)',
              background: 'var(--color-surface)', fontSize: 'var(--font-sm)',
              lineHeight: 1.6, whiteSpace: 'pre-wrap',
            }}>
              {invoice.notes}
            </div>
          </div>
        )}
      </div>
    </div>
  )

  const historyTab = (
    <div style={{
      padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)',
    }}>
      <Clock size={32} style={{ marginBottom: 'var(--space-3)', opacity: 0.5 }} />
      <div style={{ fontSize: 'var(--font-sm)' }}>Riwayat pembayaran belum tersedia.</div>
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/finance/invoices')}
      icon={<FileText size={20} />}
      title={isLoading ? 'Memuat...' : (invoice?.invoice_number || 'Invoice')}
      badges={
        <span style={{
          display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      }
      actions={actions}
      tabs={[
        { id: 'summary', label: 'Ringkasan', icon: <FileText size={14} />, content: summaryTab },
        { id: 'history', label: 'Riwayat', icon: <Clock size={14} />, content: historyTab },
      ]}
    />
  )
}
