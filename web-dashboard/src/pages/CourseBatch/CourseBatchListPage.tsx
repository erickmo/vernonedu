import { useNavigate } from 'react-router-dom'
import { Pencil, Calendar } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { courseBatchService } from '@/services/course-batch.service'

interface Batch {
  id: string
  batch_name: string
  course_name: string
  facilitator_name?: string
  start_date: number
  end_date: number
  is_active: boolean
  enrollment_count: number
  max_participants: number
  payment_method: string
  price: number
}

function formatDate(ts: number) {
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric',
  }).format(new Date(ts * 1000))
}

function formatPrice(amount: number) {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency', currency: 'IDR', minimumFractionDigits: 0,
  }).format(amount)
}

const columns: ColumnDef<Batch>[] = [
  {
    key: 'batch_name',
    header: 'Batch Kelas',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Calendar size={16} />
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.batch_name}</div>
          <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
            {row.course_name}
          </div>
        </div>
      </div>
    ),
  },
  {
    key: 'facilitator_name',
    header: 'Fasilitator',
    sortable: true,
    width: 160,
    render: (_v, row) => row.facilitator_name || '—',
  },
  {
    key: 'dates',
    header: 'Tanggal',
    sortable: false,
    width: 180,
    render: (_v, row) => (
      <div style={{ fontSize: 'var(--font-sm)' }}>
        <div>{formatDate(row.start_date)}</div>
        {row.end_date !== row.start_date && (
          <div style={{ color: 'var(--color-text-tertiary)', marginTop: 2 }}>
            s/d {formatDate(row.end_date)}
          </div>
        )}
      </div>
    ),
  },
  {
    key: 'enrollment',
    header: 'Peserta',
    sortable: true,
    width: 100,
    align: 'center',
    render: (_v, row) => {
      const max = row.max_participants || '∞'
      return `${row.enrollment_count}/${max}`
    },
  },
  {
    key: 'is_active',
    header: 'Status',
    width: 90,
    align: 'center',
    render: (_v, row) => (
      <span style={{
        display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
        fontSize: 'var(--font-xs)', fontWeight: 600,
        background: row.is_active ? 'var(--color-success-light)' : 'var(--color-surface-alt)',
        color: row.is_active ? 'var(--color-success-dark)' : 'var(--color-text-tertiary)',
      }}>
        {row.is_active ? 'Aktif' : 'Selesai'}
      </span>
    ),
  },
  {
    key: 'price',
    header: 'Harga',
    sortable: true,
    width: 140,
    align: 'right',
    render: (_v, row) => (
      <span style={{ fontWeight: 600, fontSize: 'var(--font-sm)' }}>
        {formatPrice(row.price)}
      </span>
    ),
  },
]

const filterDefs: FilterDef[] = [
  {
    key: 'is_active',
    label: 'Status',
    type: 'select',
    options: [
      { label: 'Semua', value: '' },
      { label: 'Aktif', value: 'true' },
      { label: 'Selesai', value: 'false' },
    ],
  },
  {
    key: 'payment_method',
    label: 'Metode Pembayaran',
    type: 'select',
    options: [
      { label: 'Semua', value: '' },
      { label: 'Pembayaran Penuh', value: 'upfront' },
      { label: 'Terjadwal', value: 'scheduled' },
      { label: 'Bulanan', value: 'monthly' },
      { label: 'Sekaligus', value: 'batch_lump' },
      { label: 'Per Sesi', value: 'per_session' },
    ],
  },
]

export default function CourseBatchListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Batch>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/course-batches/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Batch>
      title="Batch Kelas"
      addLabel="Tambah Batch"
      onAdd={() => navigate('/course-batches/new')}
      queryKey="course-batches"
      fetcher={(params) => courseBatchService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/course-batches/${row.id}`)}
      searchPlaceholder="Cari batch kelas..."
      exportFilename="batch-kelas"
      filterDefs={filterDefs}
      emptyTitle="Belum ada batch kelas"
      emptyDescription="Buat batch kelas pertama untuk mulai menjadwalkan kursus."
      helpTitle="Batch Kelas"
      helpText="Batch kelas adalah jadwal pelatihan nyata dengan fasilitator, lokasi, dan peserta terdaftar. Setiap batch memiliki sistem pembayaran, komisi, dan tracking pendapatan."
      deleteConfig={{
        onDelete: (row) => courseBatchService.delete(row.id),
        dialogTitle: 'Hapus Batch Kelas?',
        dialogBody: (row) => `${row.batch_name} akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) => `Batch "${row.batch_name}" berhasil dihapus`,
        errorMessage: 'Gagal menghapus batch kelas',
      }}
    />
  )
}
