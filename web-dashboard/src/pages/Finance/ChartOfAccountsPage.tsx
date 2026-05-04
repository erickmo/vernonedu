import { useNavigate } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { accountingService } from '@/services/accounting.service'
import type { PaginatedResponse } from '@/types/api.types'
import type { ListParams } from '@/services/createEntityService'

interface CoaAccount {
  id: string
  code: string
  name: string
  type: string
  normal_balance: string
  description: string
  parent_id?: string
}

const TYPE_BADGE_STYLES: Record<string, { bg: string; color: string; label: string }> = {
  aset: { bg: 'var(--color-info-light)', color: 'var(--color-info-dark)', label: 'Aset' },
  kewajiban: { bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)', label: 'Kewajiban' },
  ekuitas: { bg: 'var(--color-success-light)', color: 'var(--color-success-dark)', label: 'Ekuitas' },
  pendapatan: { bg: 'var(--color-success-light)', color: 'var(--color-success-dark)', label: 'Pendapatan' },
  beban: { bg: 'var(--color-error-light)', color: 'var(--color-error-dark)', label: 'Beban' },
}

const columns: ColumnDef<CoaAccount>[] = [
  {
    key: 'code',
    header: 'Kode',
    sortable: true,
    width: 120,
    render: (_v, row) => (
      <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 'var(--font-sm)' }}>
        {row.code}
      </span>
    ),
  },
  {
    key: 'name',
    header: 'Nama Akun',
    sortable: true,
    render: (_v, row) => (
      <div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.name}</div>
      </div>
    ),
  },
  {
    key: 'type',
    header: 'Jenis',
    sortable: true,
    width: 130,
    render: (_v, row) => {
      const style = TYPE_BADGE_STYLES[row.type?.toLowerCase()] ?? {
        bg: 'var(--color-surface-alt)',
        color: 'var(--color-text-tertiary)',
        label: row.type ?? '—',
      }
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: style.bg, color: style.color,
        }}>
          {style.label}
        </span>
      )
    },
  },
  {
    key: 'normal_balance',
    header: 'Saldo Normal',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const isDebit = row.normal_balance?.toLowerCase() === 'debit'
      return (
        <span style={{
          fontSize: 'var(--font-sm)', fontWeight: 500,
          color: isDebit ? 'var(--color-text-primary)' : 'var(--color-text-secondary)',
        }}>
          {isDebit ? 'Debit' : 'Kredit'}
        </span>
      )
    },
  },
  {
    key: 'description',
    header: 'Deskripsi',
    render: (_v, row) => (
      <span style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>
        {row.description
          ? row.description.length > 80
            ? row.description.slice(0, 80) + '...'
            : row.description
          : '—'}
      </span>
    ),
  },
]

async function coaFetcher(_params: ListParams): Promise<PaginatedResponse<CoaAccount>> {
  const data = await accountingService.listCoa()
  const items: CoaAccount[] = Array.isArray(data) ? data : (data as any)?.items ?? []
  return { items, total: items.length, limit: 9999, offset: 0 }
}

export default function ChartOfAccountsPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<CoaAccount>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/finance/chart-of-accounts/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<CoaAccount>
      title="Chart of Accounts"
      addLabel="Tambah Akun"
      onAdd={() => navigate('/finance/chart-of-accounts/new')}
      queryKey="coa"
      fetcher={coaFetcher}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari akun..."
      exportFilename="chart-of-accounts"
      hidePagination={true}
      emptyTitle="Belum ada akun"
      emptyDescription="Buat akun pertama untuk mulai mengelola pembukuan."
      helpTitle="Chart of Accounts"
      helpText="Daftar akun yang digunakan dalam pembukuan. Setiap akun memiliki kode, jenis (Aset, Kewajiban, Ekuitas, Pendapatan, Beban), dan saldo normal (Debit/Kredit)."
    />
  )
}
