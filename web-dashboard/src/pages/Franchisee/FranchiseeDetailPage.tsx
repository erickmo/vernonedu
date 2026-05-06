import { useParams, useNavigate } from 'react-router-dom'
import { Store, Pencil, FileText, DollarSign, TrendingUp } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import type { PaginatedResponse } from '@/types/api.types'
import {
  franchiseeService,
  type Franchisee,
  type FranchiseAgreement,
  type RoyaltyPayment,
  type OtherRevenue,
} from '@/services/franchisee.service'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatCurrency(amount: number | undefined): string {
  if (amount === undefined || amount === null) return '—'
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(amount)
}

function formatDate(dateStr: string | undefined): string {
  if (!dateStr) return '—'
  return new Intl.DateTimeFormat('id-ID').format(new Date(dateStr))
}

// ─── Sub-components ───────────────────────────────────────────────────────────

function InfoRow({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: 'var(--space-2) 0', borderBottom: '1px solid var(--color-border)',
    }}>
      <span style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>{label}</span>
      <span style={{ fontWeight: 500, fontSize: 'var(--font-sm)' }}>{value ?? '—'}</span>
    </div>
  )
}

const STATUS_BADGE_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:     { label: 'Aktif',    bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  inactive:   { label: 'Nonaktif', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  terminated: { label: 'Diakhiri', bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
  unpaid:     { label: 'Belum Bayar', bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  overdue:    { label: 'Terlambat',   bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
  paid:       { label: 'Lunas',       bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
}

function StatusBadge({ status }: { status: string | undefined }) {
  const cfg = STATUS_BADGE_CONFIG[status ?? ''] ?? { label: status ?? '—', bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }
  return (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600,
      background: cfg.bg, color: cfg.color,
    }}>
      {cfg.label}
    </span>
  )
}

// ─── Section content components ───────────────────────────────────────────────

function FranchiseeInfoContent({ franchisee }: { franchisee: Franchisee | undefined }) {
  if (!franchisee) return <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Memuat data...</p>
  return (
    <div style={{ display: 'flex', flexDirection: 'column' }}>
      <InfoRow label="Nama" value={franchisee.name} />
      <InfoRow label="Nama Cabang" value={franchisee.branch_name} />
      <InfoRow label="Lokasi" value={franchisee.location} />
      <InfoRow label="Kontak" value={franchisee.contact} />
      <InfoRow label="Status" value={<StatusBadge status={franchisee.status} />} />
      <InfoRow label="Dibuat" value={formatDate(franchisee.created_at)} />
    </div>
  )
}

function AgreementContent({ agreement }: { agreement: FranchiseAgreement | undefined }) {
  if (!agreement) return <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada perjanjian.</p>
  return (
    <div style={{ display: 'flex', flexDirection: 'column' }}>
      <InfoRow label="Buy-in Fee" value={formatCurrency(agreement.buy_in_fee)} />
      <InfoRow label="Royalti Bulanan" value={formatCurrency(agreement.monthly_royalty)} />
      <InfoRow label="Royalti Pendapatan" value={`${agreement.revenue_royalty_pct ?? 0}%`} />
      <InfoRow label="Tanggal Mulai" value={formatDate(agreement.start_date)} />
      <InfoRow label="Tanggal Berakhir" value={formatDate(agreement.end_date)} />
      <InfoRow label="Status" value={<StatusBadge status={agreement.status} />} />
    </div>
  )
}

const TABLE_CELL_STYLE: React.CSSProperties = {
  padding: 'var(--space-2) var(--space-3)',
  fontSize: 'var(--font-sm)',
  borderBottom: '1px solid var(--color-border)',
  textAlign: 'left',
}

function RoyaltyContent({ payments }: { payments: RoyaltyPayment[] | undefined }) {
  if (!payments || payments.length === 0) {
    return <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada data royalti.</p>
  }
  return (
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ background: 'var(--color-surface-alt)' }}>
            {['Periode', 'Pendapatan Kotor', 'Royalti Bulanan', 'Royalti Pendapatan', 'Total', 'Status', 'Dibayar'].map((h) => (
              <th key={h} style={{ ...TABLE_CELL_STYLE, fontWeight: 600, color: 'var(--color-text-secondary)' }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {payments.map((p) => (
            <tr key={p.id}>
              <td style={TABLE_CELL_STYLE}>{p.period}</td>
              <td style={TABLE_CELL_STYLE}>{formatCurrency(p.gross_revenue)}</td>
              <td style={TABLE_CELL_STYLE}>{formatCurrency(p.monthly_royalty)}</td>
              <td style={TABLE_CELL_STYLE}>{formatCurrency(p.revenue_royalty)}</td>
              <td style={{ ...TABLE_CELL_STYLE, fontWeight: 600 }}>{formatCurrency(p.total_royalty)}</td>
              <td style={TABLE_CELL_STYLE}><StatusBadge status={p.status} /></td>
              <td style={TABLE_CELL_STYLE}>{formatDate(p.paid_at)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function OtherRevenueContent({ revenues }: { revenues: OtherRevenue[] | undefined }) {
  if (!revenues || revenues.length === 0) {
    return <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada data pendapatan lain.</p>
  }
  return (
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ background: 'var(--color-surface-alt)' }}>
            {['Keterangan', 'Jumlah', 'Tanggal'].map((h) => (
              <th key={h} style={{ ...TABLE_CELL_STYLE, fontWeight: 600, color: 'var(--color-text-secondary)' }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {revenues.map((r) => (
            <tr key={r.id}>
              <td style={TABLE_CELL_STYLE}>{r.label}</td>
              <td style={{ ...TABLE_CELL_STYLE, fontWeight: 600 }}>{formatCurrency(r.amount)}</td>
              <td style={TABLE_CELL_STYLE}>{formatDate(r.revenue_date)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function FranchiseeDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()

  const { data: franchisee } = useQuery({
    queryKey: ['franchisee', id],
    queryFn: () => franchiseeService.getById(id!),
    enabled: Boolean(id),
  })

  const { data: agreementData } = useQuery({
    queryKey: ['franchisee-agreement', id],
    queryFn: () => franchiseeService.getAgreement(id!),
    enabled: Boolean(id),
  })

  const { data: royaltyData } = useQuery({
    queryKey: ['franchisee-royalty', id],
    queryFn: () => franchiseeService.listRoyaltyPayments(id!),
    enabled: Boolean(id),
  })

  const { data: otherRevenueData } = useQuery({
    queryKey: ['franchisee-other-revenue', id],
    queryFn: () => franchiseeService.listOtherRevenue(id!),
    enabled: Boolean(id),
  })

  const royaltyPayments = (royaltyData as PaginatedResponse<RoyaltyPayment> | undefined)?.items ?? []
  const otherRevenues = (otherRevenueData as PaginatedResponse<OtherRevenue> | undefined)?.items ?? []
  const agreement = (agreementData as { data: FranchiseAgreement } | FranchiseAgreement | undefined)?.data ?? agreementData

  const actions: DetailPageAction[] = [
    {
      label: 'Edit Franchisee',
      icon: <Pencil size={14} />,
      onClick: () => navigate(`/pengembangan/franchisees/${id}/edit`),
      variant: 'default',
    },
  ]

  return (
    <DetailPageTemplate
      icon={<Store size={20} />}
      title={franchisee?.name ?? 'Franchisee'}
      onBack={() => navigate('/pengembangan/franchisees')}
      backLabel="Franchisee"
      badges={franchisee ? <StatusBadge status={franchisee.status} /> : undefined}
      actions={actions}
      sections={[
        {
          id: 'info',
          label: 'Info',
          icon: <Store size={14} />,
          tabs: [
            {
              id: 'info-detail',
              label: 'Detail',
              content: <FranchiseeInfoContent franchisee={franchisee} />,
            },
          ],
        },
        {
          id: 'agreement',
          label: 'Perjanjian',
          icon: <FileText size={14} />,
          tabs: [
            {
              id: 'agreement-detail',
              label: 'Perjanjian Franchise',
              content: <AgreementContent agreement={agreement} />,
            },
          ],
        },
        {
          id: 'royalty',
          label: 'Royalty Payments',
          icon: <DollarSign size={14} />,
          tabs: [
            {
              id: 'royalty-list',
              label: 'Pembayaran Royalti',
              content: <RoyaltyContent payments={royaltyPayments} />,
            },
          ],
        },
        {
          id: 'other-revenue',
          label: 'Pendapatan Lain',
          icon: <TrendingUp size={14} />,
          tabs: [
            {
              id: 'other-revenue-list',
              label: 'Pendapatan Lain',
              content: <OtherRevenueContent revenues={otherRevenues} />,
            },
          ],
        },
      ]}
    />
  )
}
