import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { financeReportsService } from '@/services/finance-reports.service'

const currencyFmt = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 })
const fmt = (n: number | undefined) => n != null ? currencyFmt.format(n) : '—'

const SECTIONS = [
  { key: 'operating', label: 'Aktivitas Operasi' },
  { key: 'investing', label: 'Aktivitas Investasi' },
  { key: 'financing', label: 'Aktivitas Pendanaan' },
] as const

export default function CashFlowPage() {
  const now = new Date()
  const [period, setPeriod] = useState(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`)

  const { data, isLoading, error } = useQuery({
    queryKey: ['finance/reports/cash-flow', period],
    queryFn: () => financeReportsService.getCashFlow({ period }),
  })

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 28 }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, margin: 0 }}>Arus Kas</h1>
        <input type="month" value={period} onChange={e => setPeriod(e.target.value)}
          style={{ padding: '6px 12px', border: '1px solid var(--color-border)', borderRadius: 8, fontSize: 'var(--font-sm)' }} />
      </div>

      {isLoading && <div style={{ color: 'var(--color-text-secondary)' }}>Memuat data...</div>}
      {error && <div style={{ color: 'var(--color-error)' }}>Gagal memuat laporan.</div>}

      {data && (
        <div style={{ maxWidth: 800 }}>
          {SECTIONS.map(s => {
            const section = data[s.key]
            if (!section?.items) return null
            return (
              <div key={s.key} style={{ marginBottom: 24 }}>
                <div style={{ fontWeight: 700, padding: '10px 16px', background: 'var(--color-surface-alt)', borderRadius: '8px 8px 0 0', borderBottom: '2px solid var(--color-border)' }}>
                  {s.label}
                </div>
                {section.items.map((row: any, i: number) => (
                  <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '9px 16px', borderBottom: '1px solid var(--color-border)', background: 'var(--color-surface)', fontSize: 'var(--font-sm)' }}>
                    <span>{row.label || row.name || `Item ${i + 1}`}</span>
                    <span style={{ fontWeight: 500, color: row.amount < 0 ? 'var(--color-error)' : 'inherit' }}>{fmt(row.amount)}</span>
                  </div>
                ))}
                {section.total != null && (
                  <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 16px', background: 'var(--color-info-light)', borderRadius: '0 0 8px 8px', fontWeight: 700 }}>
                    <span>Total {s.label}</span>
                    <span>{fmt(section.total)}</span>
                  </div>
                )}
              </div>
            )
          })}

          {(data.net_change != null || data.ending_balance != null) && (
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 20px', background: 'var(--color-primary-subtle)', borderRadius: 12, fontWeight: 700, fontSize: 'var(--font-base)' }}>
              <span>Perubahan Kas Bersih</span>
              <span>{fmt(data.net_change ?? data.ending_balance)}</span>
            </div>
          )}

          {!data.operating && !data.investing && !data.financing && (
            <pre style={{ fontSize: 'var(--font-xs)', background: 'var(--color-surface-alt)', padding: 16, borderRadius: 8 }}>
              {JSON.stringify(data, null, 2)}
            </pre>
          )}
        </div>
      )}
    </div>
  )
}
