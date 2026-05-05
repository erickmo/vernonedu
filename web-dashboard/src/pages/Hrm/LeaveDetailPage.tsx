import { useParams, useNavigate } from 'react-router-dom'
import { CalendarOff, User, Calendar, FileText, CheckCircle, XCircle } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { hrmService } from '@/services/hrm.service'
import { toast } from '@/widgets/Toast/Toast'
import {
  LEAVE_TYPE_LABELS, LEAVE_STATUS_LABELS, LEAVE_STATUS_COLORS,
} from '@/types/hrm.types'
import type { LeaveStatus, LeaveType } from '@/types/hrm.types'

function formatDateStr(dateStr: string | null | undefined): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'long', year: 'numeric' }).format(new Date(dateStr))
}

function formatTimestamp(ts: number | undefined): string {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(ts * 1000))
}

function calcDuration(start: string, end: string): number {
  if (!start || !end) return 0
  const diff = Math.ceil((new Date(end).getTime() - new Date(start).getTime()) / (1000 * 60 * 60 * 24)) + 1
  return diff > 0 ? diff : 0
}

function InfoRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: React.ReactNode }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 'var(--space-3)',
      padding: 'var(--space-2) 0',
    }}>
      <div style={{ color: 'var(--color-text-tertiary)', marginTop: 2, flexShrink: 0 }}>{icon}</div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginBottom: 2 }}>{label}</div>
        <div style={{ fontSize: 'var(--font-sm)', fontWeight: 500 }}>{value || '—'}</div>
      </div>
    </div>
  )
}

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div style={{
      padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
      border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
    }}>
      <h3 style={{
        fontSize: 'var(--font-sm)', fontWeight: 700,
        color: 'var(--color-text-secondary)', marginBottom: 'var(--space-4)',
        textTransform: 'uppercase', letterSpacing: 0.5,
      }}>
        {title}
      </h3>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-1)' }}>
        {children}
      </div>
    </div>
  )
}

export default function LeaveDetailPage() {
  const { leaveId } = useParams<{ leaveId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const { data: leave, isLoading } = useQuery<any>({
    queryKey: ['hrm-leave-detail', leaveId],
    queryFn: () => hrmService.getLeave(leaveId!),
    enabled: !!leaveId,
  })

  const status = leave?.status as LeaveStatus | undefined
  const statusColors = status ? LEAVE_STATUS_COLORS[status] : null

  async function handleReview(action: 'approved' | 'rejected') {
    if (!leaveId) return
    try {
      await hrmService.reviewLeave(leaveId, { status: action })
      toast.success(`Cuti berhasil ${action === 'approved' ? 'disetujui' : 'ditolak'}`)
      await queryClient.invalidateQueries({ queryKey: ['hrm-leave-detail', leaveId] })
      await queryClient.invalidateQueries({ queryKey: ['hrm-leaves'] })
    } catch {
      toast.error('Gagal memproses review cuti')
    }
  }

  const actions: DetailPageAction[] = [
    ...(status === 'pending' ? [
      {
        label: 'Setujui',
        icon: <CheckCircle size={14} />,
        onClick: () => handleReview('approved'),
        variant: 'success' as const,
      },
      {
        label: 'Tolak',
        icon: <XCircle size={14} />,
        onClick: () => handleReview('rejected'),
        variant: 'warning' as const,
      },
    ] : []),
  ]

  const duration = leave ? calcDuration(leave.start_date, leave.end_date) : 0

  const overviewTab = (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 'var(--space-4)' }}>
      <Card title="Karyawan">
        <InfoRow icon={<User size={14} />} label="Nama" value={leave?.employee_name} />
      </Card>
      <Card title="Detail Cuti">
        <InfoRow icon={<CalendarOff size={14} />} label="Jenis" value={leave?.leave_type ? LEAVE_TYPE_LABELS[leave.leave_type as LeaveType] : '—'} />
        <InfoRow icon={<Calendar size={14} />} label="Mulai" value={formatDateStr(leave?.start_date)} />
        <InfoRow icon={<Calendar size={14} />} label="Selesai" value={formatDateStr(leave?.end_date)} />
        <InfoRow icon={<Calendar size={14} />} label="Durasi" value={duration ? `${duration} hari` : '—'} />
      </Card>
      {leave?.reason && (
        <Card title="Alasan">
          <p style={{ fontSize: 'var(--font-sm)', lineHeight: 1.6, color: 'var(--color-text-secondary)', margin: 0 }}>
            {leave.reason}
          </p>
        </Card>
      )}
      {(leave?.reviewed_by || leave?.reviewed_at) && (
        <Card title="Review">
          <InfoRow icon={<User size={14} />} label="Direview oleh" value={leave?.reviewed_by} />
          <InfoRow icon={<Calendar size={14} />} label="Waktu review" value={formatTimestamp(leave?.reviewed_at)} />
        </Card>
      )}
      {leave && (
        <Card title="Metadata">
          <InfoRow icon={<Calendar size={14} />} label="Dibuat" value={formatTimestamp(leave.created_at)} />
          <InfoRow icon={<Calendar size={14} />} label="Diperbarui" value={formatTimestamp(leave.updated_at)} />
        </Card>
      )}
    </div>
  )

  const leaveTypeLabel = leave?.leave_type ? LEAVE_TYPE_LABELS[leave.leave_type as LeaveType] : ''

  return (
    <DetailPageTemplate
      onBack={() => navigate('/hrm/leaves')}
      icon={<CalendarOff size={20} />}
      title={isLoading ? 'Memuat...' : (leave?.employee_name ?? 'Permintaan Cuti')}
      code={leaveTypeLabel || undefined}
      badges={
        status ? (
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px',
            borderRadius: 'var(--radius-full)', fontSize: 'var(--font-xs)', fontWeight: 600,
            background: statusColors?.bg, color: statusColors?.color,
          }}>
            {LEAVE_STATUS_LABELS[status]}
          </span>
        ) : undefined
      }
      actions={actions}
      tabs={[
        { id: 'overview', label: 'Detail', icon: <FileText size={14} />, content: overviewTab },
      ]}
    />
  )
}
