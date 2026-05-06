import { useNavigate } from 'react-router-dom'
import { Users, Pencil } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { marketingService } from '@/services/marketing.service'

interface ReferralPartner {
  id: string
  name?: string
  type?: string
  partner_type?: string
  commission_rate?: number
  commission?: number
  status?: string
  is_active?: boolean
  referral_count?: number
  total_referrals?: number
  [key: string]: unknown
}

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:   { label: 'Aktif',    bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  inactive: { label: 'Nonaktif', bg: 'var(--color-danger-light)',  color: 'var(--color-danger-dark)' },
}

const columns: ColumnDef<ReferralPartner>[] = [
  {
    key: 'name',
    header: 'Nama',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--color-primary-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-primary)', flexShrink: 0,
        }}>
          <Users size={16} />
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.name || '—'}
        </div>
      </div>
    ),
  },
  {
    key: 'type',
    header: 'Jenis',
    width: 140,
    align: 'center',
    render: (_v, row) => {
      const type = row.type || row.partner_type
      if (!type) return '—'
      return (
        <span style={{
          display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
          fontSize: 'var(--font-xs)', fontWeight: 600,
          background: 'var(--color-info-light)', color: 'var(--color-info-dark)',
        }}>
          {type as string}
        </span>
      )
    },
  },
  {
    key: 'commission_rate',
    header: 'Komisi',
    width: 100,
    align: 'center',
    render: (_v, row) => {
      const val = row.commission_rate ?? row.commission
      if (val === undefined || val === null) return '—'
      return (
        <span style={{ fontWeight: 600, color: 'var(--color-success-dark)' }}>
          {val}%
        </span>
      )
    },
  },
  {
    key: 'status',
    header: 'Status',
    width: 120,
    align: 'center',
    render: (_v, row) => {
      const isActive = row.status === 'active' || row.is_active === true
      const key = isActive ? 'active' : 'inactive'
      const cfg = STATUS_CONFIG[key]
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
  {
    key: 'referral_count',
    header: 'Total Referral',
    width: 130,
    align: 'center',
    render: (_v, row) => {
      const count = row.referral_count ?? row.total_referrals ?? 0
      return (
        <span style={{ fontWeight: 600 }}>
          {count as number}
        </span>
      )
    },
  },
]

export default function ReferralListPage() {
  const navigate = useNavigate()

  const rowActions: RowActionDef<ReferralPartner>[] = [
    {
      key: 'edit',
      label: 'Edit',
      icon: <Pencil size={14} />,
      onClick: (row) => navigate(`/marketing/referral/${row.id}/edit`),
    },
  ]

  return (
    <ListPageTemplate<ReferralPartner>
      title="Partner Referral"
      addLabel="Tambah Partner Referral"
      onAdd={() => navigate('/marketing/referral/new')}
      queryKey="marketing-referral-partners"
      fetcher={(params) => marketingService.listReferralPartners(params)}
      columns={columns}
      rowActions={rowActions}
      onRowClick={(row) => navigate(`/marketing/referral/${row.id}/edit`)}
      searchPlaceholder="Cari partner referral..."
      exportFilename="referral-partners"
      emptyTitle="Belum ada partner referral"
      emptyDescription="Tambahkan partner referral untuk memperluas jangkauan promosi kursus."
      hidePagination
    />
  )
}
