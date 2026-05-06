import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Store, Pencil, FileText, DollarSign, TrendingUp, Plus, X } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { DetailPageTemplate, type DetailPageAction } from '@/widgets/DetailPageTemplate/DetailPageTemplate'
import type { PaginatedResponse } from '@/types/api.types'
import { toast } from '@/widgets/Toast/Toast'
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

function AgreementContent({ agreement, onEdit }: { agreement: FranchiseAgreement | undefined; onEdit: () => void }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 'var(--space-3)' }}>
        <button
          onClick={onEdit}
          style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '6px 12px', borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary)', color: '#fff',
            border: 'none', cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500,
          }}
        >
          {agreement ? <><Pencil size={13} />{'Edit Perjanjian'}</> : <><Plus size={13} />{'Buat Perjanjian'}</>}
        </button>
      </div>
      {agreement ? (
        <>
          <InfoRow label="Buy-in Fee" value={formatCurrency(agreement.buy_in_fee)} />
          <InfoRow label="Royalti Bulanan" value={formatCurrency(agreement.monthly_royalty)} />
          <InfoRow label="Royalti Pendapatan" value={`${agreement.revenue_royalty_pct ?? 0}%`} />
          <InfoRow label="Tanggal Mulai" value={formatDate(agreement.start_date)} />
          <InfoRow label="Tanggal Berakhir" value={formatDate(agreement.end_date)} />
          <InfoRow label="Status" value={<StatusBadge status={agreement.status} />} />
        </>
      ) : (
        <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Belum ada perjanjian.</p>
      )}
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
  const queryClient = useQueryClient()

  // ── Agreement modal state ──
  const [agreementModalOpen, setAgreementModalOpen] = useState(false)
  const [agreementForm, setAgreementForm] = useState({
    buy_in_fee: '', monthly_royalty: '', revenue_royalty_pct: '',
    start_date: '', end_date: '', status: 'active',
  })
  const [agreementSaving, setAgreementSaving] = useState(false)

  function openAgreementModal() {
    if (agreement) {
      setAgreementForm({
        buy_in_fee: String(agreement.buy_in_fee ?? ''),
        monthly_royalty: String(agreement.monthly_royalty ?? ''),
        revenue_royalty_pct: String(agreement.revenue_royalty_pct ?? ''),
        start_date: agreement.start_date ?? '',
        end_date: agreement.end_date ?? '',
        status: agreement.status ?? 'active',
      })
    } else {
      setAgreementForm({ buy_in_fee: '', monthly_royalty: '', revenue_royalty_pct: '', start_date: '', end_date: '', status: 'active' })
    }
    setAgreementModalOpen(true)
  }

  async function handleAgreementSubmit() {
    setAgreementSaving(true)
    try {
      const payload = {
        buy_in_fee: Number(agreementForm.buy_in_fee),
        monthly_royalty: Number(agreementForm.monthly_royalty),
        revenue_royalty_pct: Number(agreementForm.revenue_royalty_pct),
        start_date: agreementForm.start_date,
        end_date: agreementForm.end_date || undefined,
        status: agreementForm.status,
      }
      if (agreement) {
        await franchiseeService.updateAgreement(id!, agreement.id, payload)
      } else {
        await franchiseeService.createAgreement(id!, payload)
      }
      toast.success('Perjanjian berhasil disimpan')
      await queryClient.invalidateQueries({ queryKey: ['franchisee-agreement', id] })
      setAgreementModalOpen(false)
    } catch {
      toast.error('Gagal menyimpan perjanjian')
    } finally {
      setAgreementSaving(false)
    }
  }

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
    <>
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
                content: <AgreementContent agreement={agreement} onEdit={openAgreementModal} />,
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
      {agreementModalOpen && (
        <div
          style={{
            position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 400,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}
          onClick={() => setAgreementModalOpen(false)}
        >
          <div
            style={{
              background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--color-border)', width: 480, overflow: 'hidden',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{
              padding: 'var(--space-4) var(--space-5)', borderBottom: '1px solid var(--color-border)',
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            }}>
              <h3 style={{ fontSize: 'var(--font-base)', fontWeight: 700 }}>
                {agreement ? 'Edit Perjanjian' : 'Buat Perjanjian'}
              </h3>
              <button
                onClick={() => setAgreementModalOpen(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)' }}
              >
                <X size={16} />
              </button>
            </div>
            <div style={{ padding: 'var(--space-5)', display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
              {([
                { label: 'Buy-in Fee (IDR)', name: 'buy_in_fee' as const, type: 'number' },
                { label: 'Royalti Bulanan (IDR)', name: 'monthly_royalty' as const, type: 'number' },
                { label: 'Royalti Pendapatan (%)', name: 'revenue_royalty_pct' as const, type: 'number' },
                { label: 'Tanggal Mulai', name: 'start_date' as const, type: 'date' },
                { label: 'Tanggal Berakhir (opsional)', name: 'end_date' as const, type: 'date' },
              ]).map(({ label, name, type }) => (
                <div key={name}>
                  <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>{label}</label>
                  <input
                    type={type}
                    name={name}
                    value={agreementForm[name]}
                    onChange={(e) => setAgreementForm(f => ({ ...f, [e.target.name]: e.target.value }))}
                    style={{
                      width: '100%', padding: '8px 10px', borderRadius: 'var(--radius-md)',
                      border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                      background: 'var(--color-surface)', boxSizing: 'border-box',
                    }}
                  />
                </div>
              ))}
              <div>
                <label style={{ display: 'block', fontSize: 'var(--font-sm)', fontWeight: 500, marginBottom: 4 }}>Status</label>
                <select
                  value={agreementForm.status}
                  onChange={(e) => setAgreementForm(f => ({ ...f, status: e.target.value }))}
                  style={{
                    width: '100%', padding: '8px 10px', borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)',
                    background: 'var(--color-surface)',
                  }}
                >
                  <option value="active">Aktif</option>
                  <option value="terminated">Diakhiri</option>
                </select>
              </div>
            </div>
            <div style={{
              padding: 'var(--space-4) var(--space-5)', borderTop: '1px solid var(--color-border)',
              display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-2)',
            }}>
              <button
                onClick={() => setAgreementModalOpen(false)}
                style={{
                  padding: '8px 16px', borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--color-border)', background: 'var(--color-surface)',
                  cursor: 'pointer', fontSize: 'var(--font-sm)',
                }}
              >
                Batal
              </button>
              <button
                onClick={handleAgreementSubmit}
                disabled={agreementSaving}
                style={{
                  padding: '8px 16px', borderRadius: 'var(--radius-md)', border: 'none',
                  background: 'var(--color-primary)', color: '#fff',
                  cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500,
                }}
              >
                {agreementSaving ? 'Menyimpan...' : 'Simpan'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
