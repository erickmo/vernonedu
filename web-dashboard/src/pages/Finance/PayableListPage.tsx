import { useQueryClient } from '@tanstack/react-query'
import { CheckCircle } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { payableService } from '@/services/payable.service'
import { toast } from '@/widgets/Toast/Toast'

interface Payable {
  id: string
  vendor_name: string
  amount: number
  due_date?: string
  status: 'pending' | 'paid' | 'overdue'
  description?: string
  [key: string]: unknown
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  pending: { label: 'Menunggu',   bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  paid:    { label: 'Lunas',      bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  overdue: { label: 'Terlambat',  bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
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

const filterDefs: FilterDef[] = [
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: [
      { label: 'Semua', value: '' },
      { label: 'Menunggu', value: 'pending' },
      { label: 'Lunas', value: 'paid' },
      { label: 'Terlambat', value: 'overdue' },
    ],
  },
]

const columns: ColumnDef<Payable>[] = [
  {
    key: 'vendor_name',
    header: 'Vendor',
    sortable: true,
    render: (_v, row) => (
      <div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.vendor_name || '—'}</div>
        {row.description && (
          <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
            {row.description.length > 60 ? row.description.slice(0, 60) + '...' : row.description}
          </div>
        )}
      </div>
    ),
  },
  {
    key: 'amount',
    header: 'Jumlah',
    sortable: true,
    width: 180,
    align: 'right',
    render: (_v, row) => (
      <span style={{ fontWeight: 600 }}>{formatIDR(row.amount)}</span>
    ),
  },
  {
    key: 'due_date',
    header: 'Jatuh Tempo',
    sortable: true,
    width: 140,
    render: (_v, row) => formatDate(row.due_date),
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const cfg = STATUS_CONFIG[row.status] || STATUS_CONFIG.pending
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      )
    },
  },
]

export default function PayableListPage() {
  const queryClient = useQueryClient()

  const rowActions: RowActionDef<Payable>[] = [
    {
      key: 'markPaid',
      label: 'Tandai Lunas',
      icon: <CheckCircle size={14} />,
      onClick: async (row) => {
        try {
          await payableService.markAsPaid(row.id)
          await queryClient.invalidateQueries({ queryKey: ['finance/payables'] })
          toast.success(`Hutang ke ${row.vendor_name} ditandai lunas`)
        } catch {
          toast.error('Gagal menandai lunas')
        }
      },
      visible: (row) => row.status !== 'paid',
    },
  ]

  return (
    <ListPageTemplate<Payable>
      title="Hutang (Payable)"
      queryKey="finance/payables"
      fetcher={(params) => payableService.list(params)}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari hutang..."
      exportFilename="hutang"
      emptyTitle="Belum ada hutang"
      emptyDescription="Hutang akan muncul ketika ada tagihan dari vendor yang belum dibayar."
      helpTitle="Hutang (Payable)"
      helpText="Kelola hutang perusahaan ke vendor. Gunakan tombol 'Tandai Lunas' untuk mencatat pembayaran."
      filterDefs={filterDefs}
    />
  )
}
