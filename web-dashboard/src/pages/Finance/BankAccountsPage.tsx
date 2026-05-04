import { useNavigate } from 'react-router-dom'
import { Pencil, Landmark } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { accountingService } from '@/services/accounting.service'
import { toast } from '@/widgets/Toast/Toast'

interface BankAccount {
  id: string
  name: string
  bank_name?: string
  account_number?: string
  currency?: string
  balance?: number
  is_active?: boolean
  [key: string]: unknown
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  aktif: { label: 'Aktif', bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  nonaktif: { label: 'Nonaktif', bg: 'var(--color-error-light)', color: 'var(--color-error-dark)' },
}

const currencyFormatter = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  minimumFractionDigits: 0,
})

function formatCurrency(value: number | undefined): string {
  if (value === undefined || value === null) return '—'
  return currencyFormatter.format(value)
}

function getStatusKey(isActive?: boolean): string {
  return isActive !== false ? 'aktif' : 'nonaktif'
}

const columns: ColumnDef<BankAccount>[] = [
  {
    key: 'name',
    header: 'Nama Akun',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Landmark size={16} />
        </div>
        <span style={{ fontWeight: 700 }}>{row.name || '—'}</span>
      </div>
    ),
  },
  {
    key: 'bank_name',
    header: 'Bank',
    sortable: true,
    width: 160,
    render: (_v, row) => row.bank_name || '—',
  },
  {
    key: 'account_number',
    header: 'No. Rekening',
    width: 160,
    render: (_v, row) => (
      <span style={{ fontFamily: 'var(--font-mono, monospace)', fontSize: 'var(--font-sm)' }}>
        {row.account_number || '—'}
      </span>
    ),
  },
  {
    key: 'currency',
    header: 'Mata Uang',
    width: 100,
    align: 'center',
    render: (_v, row) => row.currency || 'IDR',
  },
  {
    key: 'balance',
    header: 'Saldo',
    width: 180,
    align: 'right',
    render: (_v, row) => (
      <span style={{ fontWeight: 600, color: 'var(--color-success-dark)' }}>
        {formatCurrency(row.balance)}
      </span>
    ),
  },
  {
    key: 'is_active',
    header: 'Status',
    width: 110,
    align: 'center',
    render: (_v, row) => {
      const cfg = STATUS_CONFIG[getStatusKey(row.is_active)]
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600, background: cfg.bg, color: cfg.color,
        }}>
          {cfg.label}
        </span>
      )
    },
  },
]

export default function BankAccountsPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<BankAccount>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/finance/bank-accounts/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<BankAccount>
      title="Rekening Bank"
      addLabel="Tambah Rekening"
      onAdd={() => toast.info('Formulir tambah rekening segera hadir')}
      queryKey="finance/bank-accounts"
      fetcher={(params) => accountingService.listBankAccounts(params)}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari rekening..."
      exportFilename="rekening-bank"
      emptyTitle="Belum ada rekening bank"
      emptyDescription="Tambahkan rekening bank untuk mencatat transaksi keuangan."
      helpTitle="Rekening Bank"
      helpText="Kelola daftar rekening bank perusahaan. Setiap rekening terhubung dengan pencatatan transaksi otomatis di sistem akuntansi."
      hidePagination
    />
  )
}
