import { useParams, useNavigate } from 'react-router-dom'
import { CalendarCheck, Pencil, Trash2, User, Clock, FileText } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import { hrmService } from '@/services/hrm.service'
import { toast } from '@/widgets/Toast/Toast'
import { ATTENDANCE_STATUS_LABELS, ATTENDANCE_STATUS_COLORS } from '@/types/hrm.types'
import type { AttendanceStatus } from '@/types/hrm.types'

function formatDateStr(dateStr: string | null | undefined): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'long', year: 'numeric' }).format(new Date(dateStr))
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

export default function AttendanceDetailPage() {
  const { attendanceId } = useParams<{ attendanceId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const { data: record, isLoading } = useQuery<any>({
    queryKey: ['hrm-attendance-detail', attendanceId],
    queryFn: () => hrmService.getAttendance(attendanceId!),
    enabled: !!attendanceId,
  })

  const status = record?.status as AttendanceStatus | undefined
  const statusColors = status ? ATTENDANCE_STATUS_COLORS[status] : null

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Kehadiran',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/hrm/attendance/${attendanceId}/edit`),
    },
    {
      label: 'Hapus',
      icon: <Trash2 size={14} />,
      onClick: async () => {
        if (!window.confirm('Yakin ingin menghapus absensi ini?')) return
        try {
          await hrmService.deleteAttendance(attendanceId!)
          toast.success('Absensi berhasil dihapus')
          navigate('/hrm/attendance')
        } catch (err) {
          toast.error(err instanceof Error ? err.message : 'Gagal menghapus absensi')
        }
      },
      variant: 'danger' as const,
    },
  ]

  const overviewTab = (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 'var(--space-4)' }}>
      <Card title="Karyawan">
        <InfoRow icon={<User size={14} />} label="Nama" value={record?.employee_name} />
      </Card>
      <Card title="Kehadiran">
        <InfoRow icon={<CalendarCheck size={14} />} label="Tanggal" value={formatDateStr(record?.date)} />
        <InfoRow icon={<Clock size={14} />} label="Jam Masuk" value={record?.clock_in} />
        <InfoRow icon={<Clock size={14} />} label="Jam Keluar" value={record?.clock_out} />
      </Card>
      {record?.note && (
        <Card title="Catatan">
          <p style={{ fontSize: 'var(--font-sm)', lineHeight: 1.6, color: 'var(--color-text-secondary)', margin: 0 }}>
            {record.note}
          </p>
        </Card>
      )}
    </div>
  )

  return (
    <DetailPageTemplate
      onBack={() => navigate('/hrm/attendance')}
      icon={<CalendarCheck size={20} />}
      title={isLoading ? 'Memuat...' : (record?.employee_name ?? 'Kehadiran')}
      code={record?.date ? formatDateStr(record.date) : undefined}
      badges={
        status ? (
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 4, padding: '2px 10px',
            borderRadius: 'var(--radius-full)', fontSize: 'var(--font-xs)', fontWeight: 600,
            background: statusColors?.bg, color: statusColors?.color,
          }}>
            {ATTENDANCE_STATUS_LABELS[status]}
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
