import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { AlertCircle, ArrowRight, Handshake } from 'lucide-react'
import { PageHeader } from '@/layouts/PageHeader/PageHeader'
import { partnerService } from '@/services/partner.service'
import type { ExpiringMOU, Partner } from '@/types/partner.types'

type MOUFilterStatus = 'active' | 'expiring' | 'expired' | 'terminated' | 'none' | ''

const MOU_BADGE_COLOR: Record<string, { bg: string; color: string }> = {
  active:     { bg: 'var(--color-success-light)',  color: 'var(--color-success-dark)' },
  expiring:   { bg: 'var(--color-warning-light)',  color: 'var(--color-warning-dark)' },
  expired:    { bg: 'var(--color-error-light)',    color: 'var(--color-error-dark)' },
  terminated: { bg: 'var(--color-surface-alt)',    color: 'var(--color-text-tertiary)' },
}

const MOU_BADGE_LABEL: Record<string, string> = {
  active:     'Aktif',
  expiring:   'Segera Berakhir',
  expired:    'Berakhir',
  terminated: 'Dihentikan',
}

const STATUS_OPTIONS: { value: MOUFilterStatus; label: string }[] = [
  { value: '',           label: 'Semua Status' },
  { value: 'active',     label: 'Aktif' },
  { value: 'expiring',   label: 'Segera Berakhir' },
  { value: 'expired',    label: 'Berakhir' },
  { value: 'terminated', label: 'Dihentikan' },
  { value: 'none',       label: 'Belum Ada MOU' },
]

function StatusBadge({ status }: { status?: string | null }) {
  const s = MOU_BADGE_COLOR[status ?? ''] ?? { bg: 'var(--color-surface-alt)', color: 'var(--color-text-tertiary)' }
  const label = MOU_BADGE_LABEL[status ?? ''] ?? 'Belum Ada MOU'
  return (
    <span style={{
      display: 'inline-block', padding: '2px 10px', borderRadius: 'var(--radius-full)',
      fontSize: 'var(--font-xs)', fontWeight: 600, background: s.bg, color: s.color,
    }}>
      {label}
    </span>
  )
}

function daysUntil(dateStr: string): number {
  return Math.ceil((new Date(dateStr).getTime() - Date.now()) / 86_400_000)
}

const cardStyle: React.CSSProperties = {
  padding: 'var(--space-5)', borderRadius: 'var(--radius-lg)',
  border: '1px solid var(--color-border)', background: 'var(--color-surface-elevated)',
  marginBottom: 'var(--space-6)',
}

const tableStyle: React.CSSProperties = { width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)' }

const thStyle: React.CSSProperties = {
  padding: '10px 12px', textAlign: 'left', fontWeight: 600,
  color: 'var(--color-text-secondary)', fontSize: 'var(--font-xs)',
  textTransform: 'uppercase', letterSpacing: '0.5px',
  background: 'var(--color-surface-alt)',
}

const tdStyle: React.CSSProperties = { padding: '10px 12px' }

interface ExpiringSectionProps {
  mous: ExpiringMOU[]
  isLoading: boolean
  onNavigate: (partnerId: string) => void
}

function ExpiringSection({ mous, isLoading, onNavigate }: ExpiringSectionProps) {
  if (isLoading) {
    return <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Memuat...</p>
  }
  if (mous.length === 0) {
    return (
      <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)', padding: 'var(--space-4) 0' }}>
        Tidak ada MOU yang akan berakhir dalam 3 bulan ke depan.
      </p>
    )
  }
  return (
    <div style={{ borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', overflow: 'hidden' }}>
      <table style={tableStyle}>
        <thead>
          <tr>
            {['Partner', 'Judul', 'No. Dokumen', 'Berakhir', 'Sisa Hari', 'Status', ''].map(h => (
              <th key={h} style={thStyle}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {mous.map((mou, i) => {
            const days = mou.end_date ? daysUntil(mou.end_date) : null
            return (
              <tr key={mou.id} style={{ borderTop: i > 0 ? '1px solid var(--color-border)' : undefined }}>
                <td style={tdStyle}>{mou.partner_name}</td>
                <td style={tdStyle}>{mou.title}</td>
                <td style={{ ...tdStyle, fontFamily: 'monospace', fontSize: 'var(--font-xs)' }}>{mou.document_number}</td>
                <td style={tdStyle}>{mou.end_date ?? '—'}</td>
                <td style={tdStyle}>
                  {days !== null ? (
                    <span style={{
                      padding: '2px 8px', borderRadius: 'var(--radius-full)',
                      background: days <= 30 ? 'var(--color-error-light)' : 'var(--color-warning-light)',
                      color: days <= 30 ? 'var(--color-error-dark)' : 'var(--color-warning-dark)',
                      fontSize: 'var(--font-xs)', fontWeight: 600,
                    }}>
                      {days} hari lagi
                    </span>
                  ) : '—'}
                </td>
                <td style={tdStyle}><StatusBadge status={mou.status} /></td>
                <td style={tdStyle}>
                  <button
                    onClick={() => onNavigate(mou.partner_id)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-primary)', display: 'flex', alignItems: 'center', gap: 4, fontSize: 'var(--font-xs)' }}
                  >
                    Detail <ArrowRight size={12} />
                  </button>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}

interface PartnersSectionProps {
  partners: Partner[]
  statusFilter: MOUFilterStatus
  onFilterChange: (v: MOUFilterStatus) => void
  onNavigate: (partnerId: string) => void
}

function PartnersSection({ partners, statusFilter, onFilterChange, onNavigate }: PartnersSectionProps) {
  const filtered = partners.filter(p => {
    if (!statusFilter) return true
    if (statusFilter === 'none') return !p.mou_status
    return p.mou_status === statusFilter
  })

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-4)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
          <Handshake size={16} />
          <h2 style={{ fontWeight: 700, fontSize: 'var(--font-base)' }}>Semua Partner</h2>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
          <label htmlFor="status-filter" style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>
            Filter Status MOU
          </label>
          <select
            id="status-filter"
            aria-label="Filter Status MOU"
            value={statusFilter}
            onChange={e => onFilterChange(e.target.value as MOUFilterStatus)}
            style={{ padding: '6px 10px', borderRadius: 'var(--radius-md)', fontSize: 'var(--font-sm)', border: '1px solid var(--color-border)', background: 'var(--color-surface)' }}
          >
            {STATUS_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
        </div>
      </div>

      <div style={{ borderRadius: 'var(--radius-md)', border: '1px solid var(--color-border)', overflow: 'hidden' }}>
        <table style={tableStyle}>
          <thead>
            <tr>
              {['Nama Partner', 'Status MOU', 'Aksi'].map(h => <th key={h} style={thStyle}>{h}</th>)}
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={3} style={{ ...tdStyle, textAlign: 'center', color: 'var(--color-text-tertiary)' }}>
                  Tidak ada partner yang sesuai filter.
                </td>
              </tr>
            ) : filtered.map((partner, i) => (
              <tr key={partner.id} style={{ borderTop: i > 0 ? '1px solid var(--color-border)' : undefined }}>
                <td style={tdStyle}>{partner.name}</td>
                <td style={tdStyle}><StatusBadge status={partner.mou_status} /></td>
                <td style={tdStyle}>
                  <button
                    onClick={() => onNavigate(partner.id)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-primary)', display: 'flex', alignItems: 'center', gap: 4, fontSize: 'var(--font-xs)' }}
                  >
                    Lihat Detail <ArrowRight size={12} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  )
}

export default function PartnerMOUListPage() {
  const navigate = useNavigate()
  const [statusFilter, setStatusFilter] = useState<MOUFilterStatus>('')

  const { data: expiringMOUs = [], isLoading: loadingExpiring } = useQuery({
    queryKey: ['mous-expiring', 3],
    queryFn: () => partnerService.listExpiringMOUs(3),
  })

  const { data: partnersData } = useQuery({
    queryKey: ['partners-all'],
    queryFn: () => partnerService.list({ limit: 200 }),
  })

  const allPartners: Partner[] = partnersData?.items ?? []

  return (
    <div>
      <PageHeader title="Perjanjian MOU" subtitle="Monitor status MOU semua partner" />

      <div style={cardStyle}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', marginBottom: 'var(--space-4)' }}>
          <AlertCircle size={16} style={{ color: 'var(--color-warning-dark)' }} />
          <h2 style={{ fontWeight: 700, fontSize: 'var(--font-base)' }}>MOU Segera Berakhir (3 bulan ke depan)</h2>
        </div>
        <ExpiringSection
          mous={expiringMOUs}
          isLoading={loadingExpiring}
          onNavigate={(id) => navigate(`/partners/${id}`)}
        />
      </div>

      <div style={cardStyle}>
        <PartnersSection
          partners={allPartners}
          statusFilter={statusFilter}
          onFilterChange={setStatusFilter}
          onNavigate={(id) => navigate(`/partners/${id}`)}
        />
      </div>
    </div>
  )
}
