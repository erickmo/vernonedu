import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Store, TrendingUp, AlertCircle } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { franchiseeService, type Franchisee } from '@/services/franchisee.service'

const STATUS_CONFIG: Record<string, { label: string; bg: string; color: string }> = {
  active:     { label: 'Aktif',     bg: 'var(--color-success-light)', color: 'var(--color-success-dark)' },
  inactive:   { label: 'Nonaktif',  bg: 'var(--color-warning-light)', color: 'var(--color-warning-dark)' },
  terminated: { label: 'Diakhiri', bg: 'var(--color-error-light)',   color: 'var(--color-error-dark)' },
}

const CELL: React.CSSProperties = {
  padding: 'var(--space-3) var(--space-4)', fontSize: 'var(--font-sm)',
  borderBottom: '1px solid var(--color-border)', textAlign: 'left',
}

export default function FranchiseManagementPage() {
  const navigate = useNavigate()
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')

  const { data } = useQuery({
    queryKey: ['franchisees-management'],
    queryFn: () => franchiseeService.list({ limit: 1000 }),
  })

  const all: Franchisee[] = data?.items ?? []
  const totalCount = all.length
  const activeCount = all.filter(f => f.status === 'active').length
  const inactiveCount = all.filter(f => f.status !== 'active').length

  const filtered = all.filter(f => {
    const q = search.toLowerCase()
    const matchSearch = !q || f.name.toLowerCase().includes(q) || f.branch_name.toLowerCase().includes(q)
    const matchStatus = !statusFilter || f.status === statusFilter
    return matchSearch && matchStatus
  })

  return (
    <div style={{ padding: 'var(--space-6)', maxWidth: 1200 }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, marginBottom: 'var(--space-6)' }}>
        Manajemen Franchise
      </h1>

      {/* Summary cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 'var(--space-4)', marginBottom: 'var(--space-6)' }}>
        {[
          { label: 'Total Franchisee', value: totalCount, icon: <Store size={20} />, color: 'var(--color-primary)' },
          { label: 'Aktif', value: activeCount, icon: <TrendingUp size={20} />, color: 'var(--color-success)' },
          { label: 'Nonaktif / Diakhiri', value: inactiveCount, icon: <AlertCircle size={20} />, color: 'var(--color-warning)' },
        ].map(card => (
          <div key={card.label} style={{
            background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--color-border)', padding: 'var(--space-4) var(--space-5)',
            display: 'flex', alignItems: 'center', gap: 'var(--space-4)',
          }}>
            <div style={{ color: card.color, flexShrink: 0 }}>{card.icon}</div>
            <div>
              <div style={{ fontSize: 'var(--font-2xl)', fontWeight: 700 }}>{card.value}</div>
              <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)' }}>{card.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Filter bar */}
      <div style={{ display: 'flex', gap: 'var(--space-3)', marginBottom: 'var(--space-4)' }}>
        <input
          placeholder="Cari nama / cabang..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          style={{ flex: 1, padding: '8px 12px', borderRadius: 'var(--radius-md)',
            border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)', background: 'var(--color-surface)' }}
        />
        <select
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
          style={{ padding: '8px 12px', borderRadius: 'var(--radius-md)',
            border: '1px solid var(--color-border)', fontSize: 'var(--font-sm)', background: 'var(--color-surface)' }}
        >
          <option value="">Semua Status</option>
          <option value="active">Aktif</option>
          <option value="inactive">Nonaktif</option>
          <option value="terminated">Diakhiri</option>
        </select>
      </div>

      {/* Table */}
      <div style={{ background: 'var(--color-surface-elevated)', borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--color-border)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: 'var(--color-surface-alt)' }}>
              {['Nama', 'Cabang', 'Lokasi', 'Kontak', 'Status', 'Aksi'].map(h => (
                <th key={h} style={{ ...CELL, fontWeight: 600, color: 'var(--color-text-secondary)',
                  borderBottom: '1px solid var(--color-border)' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ padding: 'var(--space-8)', textAlign: 'center',
                  color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>
                  Tidak ada data franchisee.
                </td>
              </tr>
            ) : filtered.map(f => {
              const cfg = STATUS_CONFIG[f.status] ?? STATUS_CONFIG.inactive
              return (
                <tr key={f.id}>
                  <td style={{ ...CELL, fontWeight: 600 }}>{f.name}</td>
                  <td style={CELL}>{f.branch_name}</td>
                  <td style={CELL}>{f.location}</td>
                  <td style={CELL}>{f.contact}</td>
                  <td style={CELL}>
                    <span style={{ display: 'inline-block', padding: '2px 10px',
                      borderRadius: 'var(--radius-full)', fontSize: 'var(--font-xs)', fontWeight: 600,
                      background: cfg.bg, color: cfg.color }}>
                      {cfg.label}
                    </span>
                  </td>
                  <td style={CELL}>
                    <button
                      onClick={() => navigate(`/pengembangan/franchisees/${f.id}`)}
                      style={{ padding: '5px 12px', borderRadius: 'var(--radius-md)',
                        border: '1px solid var(--color-border)', background: 'var(--color-surface)',
                        cursor: 'pointer', fontSize: 'var(--font-xs)', fontWeight: 500 }}
                    >
                      Lihat Detail
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
