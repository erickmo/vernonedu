import { useNavigate } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { CheckCircle, ThumbsUp, XCircle } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { payableService } from '@/services/payable.service'
import { toast } from '@/widgets/Toast/Toast'

interface Payable {
  id: string
  vendor_name?: string
  description?: string
  type?: string
  amount: number
  due_date?: string
  status: 'pending' | 'approved' | 'paid' | 'overdue' | 'cancelled'
  [key: string]: unknown
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  pending:   { label: 'Menunggu',   bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  approved:  { label: 'Disetujui', bg: 'var(--color-info-light)',    color: 'var(--color-info-dark)' },
  paid:      { label: 'Lunas',      bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  overdue:   { label: 'Terlambat',  bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
  cancelled: { label: 'Dibatalkan', bg: 'var(--color-surface-alt)',   color: 'var(--color-text-tertiary)' },
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
      { label: 'Disetujui', value: 'approved' },
      { label: 'Lunas', value: 'paid' },
      { label: 'Terlambat', value: 'overdue' },
      { label: 'Dibatalkan', value: 'cancelled' },
    ],
  },
]

const columns: ColumnDef<Payable>[] = [
  {
    key: 'description',
    header: 'Deskripsi / Penerima',
    sortable: true,
    render: (_v, row) => (
      <div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.description || row.vendor_name || '—'}
        </div>
        {row.type && (
          <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)', marginTop: 2 }}>
            {row.type}
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
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const rowActions: RowActionDef<Payable>[] = [
    {
      key: 'approve',
      label: 'Setujui',
      icon: <ThumbsUp size={14} />,
      onClick: async (row) => {
        try {
          await payableService.approve(row.id)
          await queryClient.invalidateQueries({ queryKey: ['finance/payables'] })
          toast.success('Tagihan berhasil disetujui')
        } catch {
          toast.error('Gagal menyetujui tagihan')
        }
      },
      visible: (row) => row.status === 'pending',
    },
    {
      key: 'markPaid',
      label: 'Tandai Lunas',
      icon: <CheckCircle size={14} />,
      onClick: async (row) => {
        try {
          await payableService.markAsPaid(row.id)
          await queryClient.invalidateQueries({ queryKey: ['finance/payables'] })
          toast.success('Tagihan ditandai lunas')
        } catch {
          toast.error('Gagal menandai lunas')
        }
      },
      visible: (row) => row.status === 'approved',
    },
    {
      key: 'cancel',
      label: 'Batalkan',
      icon: <XCircle size={14} />,
      variant: 'danger',
      onClick: async (row) => {
        try {
          await payableService.cancel(row.id)
          await queryClient.invalidateQueries({ queryKey: ['finance/payables'] })
          toast.success('Tagihan dibatalkan')
        } catch {
          toast.error('Gagal membatalkan tagihan')
        }
      },
      visible: (row) => row.status !== 'paid' && row.status !== 'cancelled',
    },
  ]

  return (
    <ListPageTemplate<Payable>
      title="Hutang (Payable)"
      addLabel="Tambah Tagihan"
      onAdd={() => navigate('/finance/payables/new')}
      queryKey="finance/payables"
      fetcher={(params) => payableService.list(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/finance/payables/${row.id}`)}
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
