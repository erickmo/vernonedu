import { useNavigate } from 'react-router-dom'
import { Store } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef } from '@/widgets/DataTable/DataTable'
import { franchiseeService, type Franchisee } from '@/services/franchisee.service'

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:     { label: 'Aktif',      bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  inactive:   { label: 'Nonaktif',   bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  terminated: { label: 'Diakhiri',   bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
}

const columns: ColumnDef<Franchisee>[] = [
  {
    key: 'name',
    header: 'Franchisee',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Store size={16} />
        </div>
        <div>
          <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{row.name || '—'}</div>
          {row.branch_name && (
            <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginTop: 1 }}>
              {row.branch_name}
            </div>
          )}
        </div>
      </div>
    ),
  },
  {
    key: 'location',
    header: 'Lokasi',
    width: 200,
    render: (_v, row) => <span>{row.location || '—'}</span>,
  },
  {
    key: 'status',
    header: 'Status',
    width: 130,
    align: 'center',
    render: (_v, row) => {
      const cfg = STATUS_CONFIG[row.status] ?? STATUS_CONFIG.inactive
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

export default function FranchiseeListPage() {
  const navigate = useNavigate()

  return (
    <ListPageTemplate<Franchisee>
      title="Franchisee"
      addLabel="Tambah Franchisee"
      onAdd={() => navigate('/pengembangan/franchisees/new')}
      queryKey="franchisees"
      fetcher={(params) => franchiseeService.list(params)}
      columns={columns}
      onRowClick={(row) => navigate(`/pengembangan/franchisees/${row.id}`)}
      searchPlaceholder="Cari franchisee..."
      exportFilename="franchisee"
      emptyTitle="Belum ada franchisee"
      emptyDescription="Tambahkan franchisee untuk mengelola cabang dan royalti."
      helpTitle="Franchisee"
      helpText="Franchisee adalah cabang atau mitra bisnis yang beroperasi di bawah brand VernonEdu dengan sistem royalti dan perjanjian franchise."
    />
  )
}
