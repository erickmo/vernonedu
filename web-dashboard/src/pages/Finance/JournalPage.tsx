import { Receipt } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef } from '@/widgets/DataTable/DataTable'
import { accountingService } from '@/services/accounting.service'

interface JournalEntry {
  id: string
  date: string
  reference_number?: string
  debit_account?: string
  credit_account?: string
  description?: string
  amount?: number
  [key: string]: unknown
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

const columns: ColumnDef<JournalEntry>[] = [
  {
    key: 'date',
    header: 'Tanggal',
    sortable: true,
    width: 130,
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
    width: 150,
    render: (_v, row) => (
      <span style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: 'var(--font-sm)' }}>
        {row.reference_number || '—'}
      </span>
    ),
  },
  {
    key: 'debit_account',
    header: 'Debit Akun',
    render: (_v, row) => row.debit_account || '—',
  },
  {
    key: 'credit_account',
    header: 'Kredit Akun',
    render: (_v, row) => row.credit_account || '—',
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
    key: 'amount',
    header: 'Jumlah',
    width: 160,
    align: 'right',
    render: (_v, row) => (
      <span style={{ fontWeight: 600 }}>{formatCurrency(row.amount)}</span>
    ),
  },
]

export default function JournalPage() {
  return (
    <ListPageTemplate<JournalEntry>
      title="Jurnal"
      queryKey="finance/journal"
      fetcher={(params) => accountingService.listTransactions(params)}
      columns={columns}
      searchPlaceholder="Cari jurnal..."
      exportFilename="jurnal"
      emptyTitle="Belum ada entri jurnal"
      emptyDescription="Jurnal akan otomatis tercipta dari setiap transaksi yang dicatat di sistem."
      helpTitle="Jurnal"
      helpText="Jurnal mencatat setiap transaksi keuangan dalam format debit dan kredit. Entri jurnal dihasilkan secara otomatis dari transaksi yang dibuat di sistem."
    />
  )
}
