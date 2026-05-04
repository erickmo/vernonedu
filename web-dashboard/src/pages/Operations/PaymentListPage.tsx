import { useNavigate } from 'react-router-dom'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { invoiceService } from '@/services/invoice.service'

interface Payment {
  id: string
  invoice_number?: string
  student_name: string
  batch_name?: string
  amount: number
  payment_method?: string
  paid_at?: string
  created_at?: string
  [key: string]: unknown
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

const METHOD_LABELS: Record<string, string> = {
  upfront: 'Penuh di Awal',
  scheduled: 'Terjadwal',
  monthly: 'Bulanan',
  batch_lump: 'Batch Lump Sum',
  per_session: 'Per Sesi',
  transfer: 'Transfer',
  cash: 'Tunai',
}

const filterDefs: FilterDef[] = [
  {
    key: 'payment_method',
    label: 'Metode',
    type: 'select',
    options: [
      { label: 'Semua', value: '' },
      { label: 'Transfer', value: 'transfer' },
      { label: 'Tunai', value: 'cash' },
      { label: 'Penuh di Awal', value: 'upfront' },
      { label: 'Terjadwal', value: 'scheduled' },
      { label: 'Bulanan', value: 'monthly' },
    ],
  },
]

const columns: ColumnDef<Payment>[] = [
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
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.student_name || '—'}
        </div>
      </div>
    ),
  },
  {
    key: 'batch_name',
    header: 'Batch',
    sortable: true,
    width: 180,
    render: (_v, row) => row.batch_name || '—',
  },
  {
    key: 'amount',
    header: 'Jumlah',
    sortable: true,
    width: 160,
    align: 'right',
    render: (_v, row) => (
      <span style={{ fontWeight: 600 }}>{formatIDR(row.amount)}</span>
    ),
  },
  {
    key: 'payment_method',
    header: 'Metode',
    width: 140,
    render: (_v, row) => METHOD_LABELS[row.payment_method ?? ''] || row.payment_method || '—',
  },
  {
    key: 'paid_at',
    header: 'Tanggal Bayar',
    sortable: true,
    width: 140,
    render: (_v, row) => formatDate(row.paid_at || row.created_at),
  },
]

export default function PaymentListPage() {
  const navigate = useNavigate()

  return (
    <ListPageTemplate<Payment>
      title="Pembayaran"
      queryKey="finance/payments"
      fetcher={(params) => invoiceService.list({ ...params, status: 'paid' })}
      columns={columns}
      onRowClick={(row) => navigate(`/finance/invoices/${row.id}`)}
      searchPlaceholder="Cari pembayaran..."
      exportFilename="pembayaran"
      emptyTitle="Belum ada pembayaran"
      emptyDescription="Pembayaran akan muncul setelah invoice ditandai lunas."
      helpTitle="Pembayaran"
      helpText="Daftar semua pembayaran yang telah diterima. Data ini berasal dari invoice yang berstatus lunas."
      filterDefs={filterDefs}
    />
  )
}
