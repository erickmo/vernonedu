import { useParams, useNavigate } from 'react-router-dom'
import { Wallet, Pencil, CheckCircle, SendHorizonal, Clock, User, CreditCard, Trash2} from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { hrmService } from '@/services/hrm.service'
import { toast } from '@/widgets/Toast/Toast'
import { PAYROLL_STATUS_LABELS, PAYROLL_STATUS_COLORS } from '@/types/hrm.types'
import type { PayrollPeriodStatus, PayrollItem } from '@/types/hrm.types'

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)
}

function formatDateStr(dateStr: string | null | undefined): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(dateStr))
}

function StatCard({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: string; color: string }) {
  return (
    <div style={{
      padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-border)',
      background: 'var(--color-surface-elevated)', display: 'flex', alignItems: 'center', gap: 'var(--space-3)',
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: 'var(--radius-md)', background: `${color}15`,
        display: 'flex', alignItems: 'center', justifyContent: 'center', color,
      }}>
        {icon}
      </div>
      <div>
        <div style={{ fontSize: 'var(--font-lg)', fontWeight: 700, lineHeight: 1.2 }}>{value}</div>
        <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>{label}</div>
      </div>
    </div>
  )
}

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: 'var(--space-2) 0', borderBottom: '1px solid var(--color-border)' }}>
      <span style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-tertiary)' }}>{label}</span>
      <span style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>{value}</span>
    </div>
  )
}

export default function PayrollDetailPage() {
  const { periodId } = useParams<{ periodId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const { data: period, isLoading } = useQuery<any>({
    queryKey: ['hrm-payroll-period-detail', periodId],
    queryFn: () => hrmService.getPayrollPeriod(periodId!),
  })

  const { data: itemsData } = useQuery({
    queryKey: ['hrm-payroll-items', periodId],
    queryFn: () => hrmService.getPayrollItems(periodId!),
  })

  const items: PayrollItem[] = itemsData?.items ?? []
  const status = period?.status as PayrollPeriodStatus | undefined
  const statusColors = status ? PAYROLL_STATUS_COLORS[status] : null
  const totalAmount = items.reduce((sum, i) => sum + (i.total_amount ?? 0), 0)

  async function handleGenerate() {
    try {
      await hrmService.generatePayroll(periodId!)
      toast.success('Payroll berhasil digenerate')
      await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-period-detail', periodId] })
      await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-items', periodId] })
      await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-periods'] })
    } catch {
      toast.error('Gagal generate payroll')
    }
  }

  async function handleApprove() {
    try {
      await hrmService.approvePayroll(periodId!)
      toast.success('Payroll berhasil disetujui')
      await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-period-detail', periodId] })
      await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-periods'] })
    } catch {
      toast.error('Gagal menyetujui payroll')
    }
  }

  async function handleDisburse() {
    try {
      await hrmService.disbursePayroll(periodId!)
      toast.success('Payroll berhasil disalurkan')
      await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-period-detail', periodId] })
      await queryClient.invalidateQueries({ queryKey: ['hrm-payroll-periods'] })
    } catch {
      toast.error('Gagal menyalurkan payroll')
    }
  }

  const actions: DetailPageAction[] = [
    ...(status === 'draft' ? [{
      label: 'Generate Payroll',
      icon: <Pencil size={14} />,
      onClick: handleGenerate,
      variant: 'default' as const,
    }] : []),
    ...(status === 'processing' ? [{
      label: 'Setujui',
      icon: <CheckCircle size={14} />,
      onClick: handleApprove,
      variant: 'success' as const,
    }] : []),
    ...(status === 'approved' ? [{
      label: 'Salurkan',
      icon: <SendHorizonal size={14} />,
      onClick: handleDisburse,
      variant: 'primary' as const,
    }] : []),
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus periode payroll ini?')) return
        try {
          await hrmService.deletePayrollPeriod(periodId!)
          toast.success('Periode payroll berhasil dihapus')
          navigate('/hrm/payroll')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus periode payroll')
        }
      },
      variant: 'danger' as const,
    },
  ]

  const summaryTab = (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 'var(--space-3)', marginBottom: 'var(--space-5)' }}>
        <StatCard icon={<User size={18} />} label="Karyawan" value={String(items.length)} color="var(--color-primary)" />
        <StatCard icon={<Wallet size={18} />} label="Total Gaji" value={formatCurrency(totalAmount)} color="var(--color-success-dark)" />
        <StatCard icon={<Clock size={18} />} label="Status" value={status ? PAYROLL_STATUS_LABELS[status] : '—'} color="var(--color-info)" />
      </div>

      <div style={{
        padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
      }}>
        <h3 style={{
          fontSize: 'var(--font-sm)', fontWeight: 700, color: 'var(--color-text-secondary)',
          marginBottom: 'var(--space-4)', textTransform: 'uppercase', letterSpacing: 0.5,
        }}>
          Detail Periode
        </h3>
        <InfoRow label="Nama Periode" value={period?.period} />
        <InfoRow label="Mulai" value={formatDateStr(period?.start_date)} />
        <InfoRow label="Selesai" value={formatDateStr(period?.end_date)} />
        {period?.notes && <InfoRow label="Catatan" value={period.notes} />}
        {period?.approved_by && <InfoRow label="Disetujui Oleh" value={period.approved_by} />}
        {period?.approved_at && <InfoRow label="Tanggal Persetujuan" value={formatDateStr(period.approved_at)} />}
        {period?.disbursed_at && <InfoRow label="Tanggal Penyaluran" value={formatDateStr(period.disbursed_at)} />}
      </div>
    </div>
  )

  const itemsTab = (
    <div>
      {items.length === 0 ? (
        <div style={{ padding: 'var(--space-8)', textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
          {status === 'draft'
            ? 'Generate payroll terlebih dahulu untuk melihat item gaji.'
            : 'Belum ada item penggajian.'}
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-2)' }}>
          {items.map((item) => (
            <div key={item.id} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: 'var(--space-4)', borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
            }}>
              <div>
                <div style={{ fontWeight: 600, fontSize: 'var(--font-sm)' }}>
                  {item.employee_name || '—'}
                </div>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginTop: 4 }}>
                  Gaji Pokok: {formatCurrency(item.base_salary)}
                  {item.facilitator_fee > 0 && ` + Fee: ${formatCurrency(item.facilitator_fee)}`}
                  {item.attendance_deduction > 0 && ` - Potongan: ${formatCurrency(item.attendance_deduction)}`}
                  {item.bonus > 0 && ` + Bonus: ${formatCurrency(item.bonus)}`}
                </div>
                {item.notes && (
                  <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginTop: 2 }}>
                    {item.notes}
                  </div>
                )}
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontWeight: 700, fontSize: 'var(--font-base)' }}>
                  {formatCurrency(item.total_amount)}
                </div>
                <span style={{
                  display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
                  fontSize: 'var(--font-xs)', fontWeight: 600, marginTop: 4,
                  background: item.status === 'paid' ? 'var(--color-success-light)' : 'var(--color-warning-light)',
                  color: item.status === 'paid' ? 'var(--color-success-dark)' : 'var(--color-warning-dark)',
                }}>
                  {item.status === 'paid' ? 'Dibayar' : 'Menunggu'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/hrm/payroll')}
      icon={<Wallet size={20} />}
      title={isLoading ? 'Memuat...' : (period?.period ?? 'Periode Payroll')}
      badges={
        status ? (
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px',
            borderRadius: 'var(--radius-full)', fontSize: 'var(--font-xs)', fontWeight: 600,
            background: statusColors?.bg, color: statusColors?.color,
          }}>
            {PAYROLL_STATUS_LABELS[status]}
          </span>
        ) : undefined
      }
      actions={actions}
      tabs={[
        { id: 'summary', label: 'Ringkasan', icon: <CreditCard size={14} />, content: summaryTab },
        { id: 'items', label: 'Item Gaji', icon: <User size={14} />, content: itemsTab },
      ]}
    />
  )
}
