import { useNavigate } from 'react-router-dom'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { hrmService } from '@/services/hrm.service'
import { ATTENDANCE_STATUS_LABELS, ATTENDANCE_STATUS_COLORS } from '@/types/hrm.types'
import type { StaffAttendance, AttendanceStatus } from '@/types/hrm.types'

const columns: ColumnDef<StaffAttendance>[] = [
  {
    key: 'employee_name',
    header: 'Karyawan',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 30, height: 30, borderRadius: 'var(--radius-full)',
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0, fontWeight: 700,
          fontSize: 'var(--font-xs)',
        }}>
          {(row.employee_name || '?').charAt(0).toUpperCase()}
        </div>
        <span style={{ fontWeight: 500 }}>{row.employee_name || '—'}</span>
      </div>
    ),
  },
  {
    key: 'date',
    header: 'Tanggal',
    sortable: true,
    width: 130,
    render: (_v, row) => {
      if (!row.date) return '—'
      return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit', month: 'short', year: 'numeric',
      }).format(new Date(row.date))
    },
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const s = row.status as AttendanceStatus
      const colors = ATTENDANCE_STATUS_COLORS[s]
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: colors?.bg ?? 'var(--color-surface-alt)',
          color: colors?.color ?? 'var(--color-text-tertiary)',
        }}>
          {ATTENDANCE_STATUS_LABELS[s] ?? s}
        </span>
      )
    },
  },
  {
    key: 'clock_in',
    header: 'Jam Masuk',
    width: 110,
    render: (_v, row) => row.clock_in || '—',
  },
  {
    key: 'clock_out',
    header: 'Jam Keluar',
    width: 110,
    render: (_v, row) => row.clock_out || '—',
  },
  {
    key: 'note',
    header: 'Catatan',
    render: (_v, row) => (
      <span style={{ color: row.note ? 'var(--color-text-secondary)' : 'var(--color-text-tertiary)' }}>
        {row.note ? (row.note.length > 60 ? row.note.slice(0, 60) + '...' : row.note) : '—'}
      </span>
    ),
  },
]

const filterDefs: FilterDef[] = [
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: Object.entries(ATTENDANCE_STATUS_LABELS).map(([value, label]) => ({ label, value })),
  },
  {
    key: 'from',
    label: 'Dari Tanggal',
    type: 'date',
  },
  {
    key: 'to',
    label: 'Sampai Tanggal',
    type: 'date',
  },
]

export default function AttendancePage() {
  const navigate = useNavigate()

  return (
    <ListPageTemplate<StaffAttendance>
        title="Kehadiran"
        addLabel="Tambah Kehadiran"
        onAdd={() => navigate('/hrm/attendance/new')}
        queryKey="hrm-attendance"
        fetcher={(params) => hrmService.listAttendance(params)}
        columns={columns}
        onRowClick={(row) => navigate(`/hrm/attendance/${row.id}`)}
        searchPlaceholder="Cari karyawan..."
        exportFilename="kehadiran"
        filterDefs={filterDefs}
        emptyTitle="Belum ada data kehadiran"
        emptyDescription="Data kehadiran akan muncul setelah karyawan melakukan absensi."
        helpTitle="Kehadiran"
        helpText="Catatan kehadiran harian karyawan mencakup jam masuk, jam keluar, dan status kehadiran."
      />
  )
}
