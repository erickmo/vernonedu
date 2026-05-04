import { useNavigate } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { enrollmentService } from '@/services/enrollment.service'

interface Enrollment {
  id: string
  student_name: string
  student_email: string
  batch_name: string
  course_name: string
  status: 'active' | 'completed' | 'withdrawn' | 'pending'
  payment_status: 'paid' | 'partial' | 'unpaid'
  payment_method: 'upfront' | 'scheduled' | 'monthly' | 'batch_lump' | 'per_session'
  enrolled_at: number
}

function getStatusBadgeColor(status: string): { bg: string; color: string } {
  switch (status) {
    case 'active': return { bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' }
    case 'completed': return { bg: 'var(--color-info-light)', color: 'var(--color-info-dark)' }
    case 'withdrawn': return { bg: 'var(--color-error-light)', color: 'var(--color-error-dark)' }
    case 'pending': return { bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' }
    default: return { bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }
  }
}

function getPaymentStatusBadgeColor(status: string): { bg: string; color: string } {
  switch (status) {
    case 'paid': return { bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' }
    case 'partial': return { bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' }
    case 'unpaid': return { bg: 'var(--color-error-light)', color: 'var(--color-error-dark)' }
    default: return { bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }
  }
}

function formatDate(ts: number | undefined) {
  if (!ts) return '—'
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  }).format(new Date(ts * 1000))
}

function getPaymentMethodLabel(method: string): string {
  const labels: Record<string, string> = {
    upfront: 'Penuh di Awal',
    scheduled: 'Terjadwal',
    monthly: 'Bulanan',
    batch_lump: 'Batch Lump Sum',
    per_session: 'Per Sesi',
  }
  return labels[method] || method
}

const columns: ColumnDef<Enrollment>[] = [
  {
    key: 'student_name',
    header: 'Siswa',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: '50%',
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0, fontSize: 'var(--font-sm)', fontWeight: 600,
        }}>
          {row.student_name?.charAt(0)?.toUpperCase() || '?'}
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.student_name || '—'}</div>
          <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>{row.student_email || '—'}</div>
        </div>
      </div>
    ),
  },
  {
    key: 'batch_name',
    header: 'Batch',
    sortable: true,
    width: 160,
    render: (_v, row) => row.batch_name || '—',
  },
  {
    key: 'course_name',
    header: 'Kursus',
    sortable: true,
    width: 200,
    render: (_v, row) => row.course_name || '—',
  },
  {
    key: 'status',
    header: 'Status',
    width: 110,
    align: 'center',
    render: (_v, row) => {
      const colors = getStatusBadgeColor(row.status)
      const labels: Record<string, string> = {
        active: 'Aktif',
        completed: 'Selesai',
        withdrawn: 'Keluar',
        pending: 'Menunggu',
      }
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: colors.bg,
          color: colors.color,
        }}>
          {labels[row.status] || row.status}
        </span>
      )
    },
  },
  {
    key: 'payment_status',
    header: 'Pembayaran',
    width: 110,
    align: 'center',
    render: (_v, row) => {
      const colors = getPaymentStatusBadgeColor(row.payment_status)
      const labels: Record<string, string> = {
        paid: 'Lunas',
        partial: 'Sebagian',
        unpaid: 'Belum Bayar',
      }
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: colors.bg,
          color: colors.color,
        }}>
          {labels[row.payment_status] || row.payment_status}
        </span>
      )
    },
  },
  {
    key: 'payment_method',
    header: 'Metode',
    width: 130,
    render: (_v, row) => getPaymentMethodLabel(row.payment_method),
  },
  {
    key: 'enrolled_at',
    header: 'Terdaftar',
    sortable: true,
    width: 110,
    align: 'center',
    render: (_v, row) => formatDate(row.enrolled_at),
  },
]

const filterDefs: FilterDef[] = [
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: [
      { label: 'Aktif', value: 'active' },
      { label: 'Selesai', value: 'completed' },
      { label: 'Keluar', value: 'withdrawn' },
      { label: 'Menunggu', value: 'pending' },
    ],
  },
  {
    key: 'payment_status',
    label: 'Pembayaran',
    type: 'select',
    options: [
      { label: 'Lunas', value: 'paid' },
      { label: 'Sebagian', value: 'partial' },
      { label: 'Belum Bayar', value: 'unpaid' },
    ],
  },
]

export default function EnrollmentListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Enrollment>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/enrollments/${row.id}`),
    },
  ]

  return (
    <ListPageTemplate<Enrollment>
      title="Pendaftaran"
      addLabel="Tambah Pendaftaran"
      onAdd={() => navigate('/enrollments/new')}
      queryKey="enrollments"
      fetcher={(params) => enrollmentService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/enrollments/${row.id}`)}
      searchPlaceholder="Cari pendaftaran..."
      exportFilename="pendaftaran"
      emptyTitle="Belum ada pendaftaran"
      emptyDescription="Daftarkan siswa ke kursus untuk mulai melacak pendaftaran."
      helpTitle="Pendaftaran"
      helpText="Pendaftaran menghubungkan siswa dengan batch kursus. Termasuk status pembayaran dan progres pendaftaran."
      filterDefs={filterDefs}
    />
  )
}
