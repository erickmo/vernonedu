import { useNavigate } from 'react-router-dom'
import { Pencil, Receipt } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef, FilterDef } from '@/widgets/DataTable/DataTable'
import { accountingService } from '@/services/accounting.service'

interface Transaction {
  id: string
  date: string
  reference_number?: string
  account_id: string
  account_name?: string
  description?: string
  type: string
  debit?: number
  credit?: number
  amount?: number
  created_at?: number
  updated_at?: number
}

const currencyFormatter = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  minimumFractionDigits: 0,
})

const dateFormatter = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'short',
  year: 'numeric',
})

function formatCurrency(value: number | undefined): string {
  if (value === undefined || value === null) return '—'
  return currencyFormatter.format(value)
}

function formatDate(date: string | undefined): string {
  if (!date) return '—'
  return dateFormatter.format(new Date(date))
}

const columns: ColumnDef<Transaction>[] = [
  {
    key: 'date',
    header: 'Tanggal',
    sortable: true,
    width: 120,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Receipt size={16} />
        </div>
        <span style={{ fontWeight: 500, fontSize: 'var(--font-sm)' }}>
          {formatDate(row.date)}
        </span>
      </div>
    ),
  },
  {
    key: 'reference_number',
    header: 'No. Referensi',
    width: 140,
    render: (_v, row) => row.reference_number || '—',
  },
  {
    key: 'account_name',
    header: 'Akun',
    sortable: true,
    render: (_v, row) => row.account_name || row.account_id || '—',
  },
  {
    key: 'description',
    header: 'Deskripsi',
    render: (_v, row) => {
      if (!row.description) return '—'
      return row.description.length > 80
        ? row.description.slice(0, 80) + '...'
        : row.description
    },
  },
  {
    key: 'debit',
    header: 'Debit',
    width: 140,
    align: 'right',
    render: (_v, row) => {
      if (!row.debit && row.type !== 'debit') return '—'
      const amount = row.debit ?? row.amount ?? 0
      return (
        <span style={{ color: 'var(--color-success-dark)', fontWeight: 600 }}>
          {formatCurrency(amount)}
        </span>
      )
    },
  },
  {
    key: 'credit',
    header: 'Kredit',
    width: 140,
    align: 'right',
    render: (_v, row) => {
      if (!row.credit && row.type !== 'credit') return '—'
      const amount = row.credit ?? row.amount ?? 0
      return (
        <span style={{ color: 'var(--color-error)', fontWeight: 600 }}>
          {formatCurrency(amount)}
        </span>
      )
    },
  },
]

const filterDefs: FilterDef[] = [
  {
    key: 'type',
    label: 'Jenis',
    type: 'select',
    options: [
      { label: 'Semua', value: '' },
      { label: 'Pemasukan', value: 'debit' },
      { label: 'Pengeluaran', value: 'credit' },
    ],
  },
]

export default function TransactionListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<Transaction>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/finance/transactions/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<Transaction>
      title="Transaksi"
      addLabel="Tambah Transaksi"
      onAdd={() => navigate('/finance/transactions/new')}
      queryKey="transactions"
      fetcher={(params) => accountingService.listTransactions(params)}
      columns={columns}
      filterDefs={filterDefs}
      rowActions={rowActions}
      searchPlaceholder="Cari transaksi..."
      exportFilename="transaksi"
      emptyTitle="Belum ada transaksi"
      emptyDescription="Buat transaksi pertama untuk mencatat alur keuangan."
      helpTitle="Transaksi"
      helpText="Transaksi mencatat semua pemasukan dan pengeluaran. Setiap transaksi terhubung ke akun di Chart of Accounts."
      deleteConfig={{
        onDelete: (row) => accountingService.deleteTransaction(row.id) as Promise<void>,
        dialogTitle: 'Hapus Transaksi?',
        dialogBody: (row) =>
          `Transaksi ${row.reference_number ? `"${row.reference_number}"` : 'ini'} akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.`,
        successMessage: (row) =>
          `Transaksi${row.reference_number ? ` "${row.reference_number}"` : ''} berhasil dihapus`,
        errorMessage: 'Gagal menghapus transaksi',
      }}
    />
  )
}
