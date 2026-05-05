import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { AlertTriangle, TrendingUp, Lightbulb } from 'lucide-react'
import { financeAnalysisService } from '@/services/finance-analysis.service'

const currencyFmt = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 })
const fmt = (n: number | undefined) => n != null ? currencyFmt.format(n) : '—'
const pct = (n: number | undefined) => n != null ? `${(n * 100).toFixed(1)}%` : '—'

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div style={{ marginBottom: 28 }}>
      <h2 style={{ fontSize: 'var(--font-base)', fontWeight: 700, margin: '0 0 12px' }}>{title}</h2>
      {children}
    </div>
  )
}

export default function FinancialAnalysisPage() {
  const now = new Date()
  const [period, setPeriod] = useState(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`)

  const { data: ratios, isLoading: loadRatios } = useQuery({
    queryKey: ['finance/analysis/ratios', period],
    queryFn: () => financeAnalysisService.getRatios({ period }),
  })

  const { data: batchProfit, isLoading: loadBatch } = useQuery({
    queryKey: ['finance/analysis/batch-profit', period],
    queryFn: () => financeAnalysisService.getBatchProfit({ period, sort: 'profit_desc', limit: 10 }),
  })

  const { data: cashForecast, isLoading: loadForecast } = useQuery({
    queryKey: ['finance/analysis/cash-forecast'],
    queryFn: () => financeAnalysisService.getCashForecast({ months: 6 }),
  })

  const { data: alerts } = useQuery({
    queryKey: ['finance/analysis/alerts'],
    queryFn: () => financeAnalysisService.getAlerts(),
  })

  const { data: suggestions } = useQuery({
    queryKey: ['finance/analysis/suggestions'],
    queryFn: () => financeAnalysisService.getSuggestions(),
  })

  const batches: any[] = Array.isArray(batchProfit) ? batchProfit : (batchProfit?.items ?? batchProfit?.data ?? [])
  const forecasts: any[] = Array.isArray(cashForecast) ? cashForecast : (cashForecast?.items ?? cashForecast?.data ?? [])
  const alertList: any[] = Array.isArray(alerts) ? alerts : (alerts?.items ?? alerts?.data ?? [])
  const suggestionList: any[] = Array.isArray(suggestions) ? suggestions : (suggestions?.items ?? suggestions?.data ?? [])

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 28 }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, margin: 0 }}>Analisis Keuangan</h1>
        <input type="month" value={period} onChange={e => setPeriod(e.target.value)}
          style={{ padding: '6px 12px', border: '1px solid var(--color-border)', borderRadius: 8, fontSize: 'var(--font-sm)' }} />
      </div>

      {/* Alerts */}
      {alertList.length > 0 && (
        <div style={{ marginBottom: 24 }}>
          {alertList.map((alert: any, i: number) => (
            <div key={i} style={{
              display: 'flex', gap: 12, padding: '12px 16px', marginBottom: 8,
              background: 'var(--color-warning-light)', borderRadius: 8,
              border: '1px solid var(--color-warning)',
            }}>
              <AlertTriangle size={18} style={{ color: 'var(--color-warning)', flexShrink: 0, marginTop: 1 }} />
              <span style={{ fontSize: 'var(--font-sm)' }}>{alert.message || alert.description || JSON.stringify(alert)}</span>
            </div>
          ))}
        </div>
      )}

      {/* Ratios */}
      <Section title="Rasio Keuangan">
        {loadRatios && <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>Memuat...</div>}
        {ratios && (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: 12 }}>
            {[
              { label: 'Current Ratio', value: ratios.current_ratio?.toFixed(2) ?? '—' },
              { label: 'Quick Ratio', value: ratios.quick_ratio?.toFixed(2) ?? '—' },
              { label: 'Net Profit Margin', value: pct(ratios.net_profit_margin) },
              { label: 'Gross Margin', value: pct(ratios.gross_margin) },
              { label: 'ROA', value: pct(ratios.roa) },
              { label: 'ROE', value: pct(ratios.roe) },
            ].map(r => (
              <div key={r.label} style={{ background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 10, padding: '14px 16px' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)', marginBottom: 6 }}>{r.label}</div>
                <div style={{ fontSize: 'var(--font-lg)', fontWeight: 700 }}>{r.value}</div>
              </div>
            ))}
          </div>
        )}
      </Section>

      {/* Batch Profitability */}
      <Section title="Profitabilitas Kelas (Top 10)">
        {loadBatch && <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>Memuat...</div>}
        {batches.length > 0 && (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)' }}>
            <thead>
              <tr style={{ background: 'var(--color-surface-alt)' }}>
                {['Kelas', 'Pendapatan', 'Beban', 'Profit', 'Margin'].map(h => (
                  <th key={h} style={{ padding: '9px 12px', borderBottom: '2px solid var(--color-border)', textAlign: 'left', fontWeight: 600 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {batches.map((b: any, i: number) => {
                const margin = b.revenue ? ((b.profit / b.revenue) * 100).toFixed(1) : null
                return (
                  <tr key={i} style={{ borderBottom: '1px solid var(--color-border)' }}>
                    <td style={{ padding: '9px 12px' }}>{b.batch_name || b.name || `Kelas ${i + 1}`}</td>
                    <td style={{ padding: '9px 12px' }}>{fmt(b.revenue)}</td>
                    <td style={{ padding: '9px 12px' }}>{fmt(b.expenses ?? b.costs)}</td>
                    <td style={{ padding: '9px 12px', fontWeight: 600, color: (b.profit ?? 0) >= 0 ? 'var(--color-success)' : 'var(--color-error)' }}>{fmt(b.profit)}</td>
                    <td style={{ padding: '9px 12px' }}>{margin ? `${margin}%` : '—'}</td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
        {!loadBatch && batches.length === 0 && (
          <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Tidak ada data</div>
        )}
      </Section>

      {/* Cash Forecast */}
      <Section title="Proyeksi Kas (6 Bulan)">
        {loadForecast && <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>Memuat...</div>}
        {forecasts.length > 0 && (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', gap: 12 }}>
            {forecasts.map((f: any, i: number) => (
              <div key={i} style={{ background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 10, padding: '14px 16px' }}>
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)', marginBottom: 6 }}>{f.month || f.period || `Bulan ${i + 1}`}</div>
                <div style={{ fontSize: 'var(--font-base)', fontWeight: 700, color: (f.net_cash ?? f.balance ?? 0) >= 0 ? 'var(--color-success)' : 'var(--color-error)' }}>
                  {fmt(f.net_cash ?? f.balance ?? f.amount)}
                </div>
              </div>
            ))}
          </div>
        )}
        {!loadForecast && forecasts.length === 0 && (
          <div style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Tidak ada data proyeksi</div>
        )}
      </Section>

      {/* Suggestions */}
      {suggestionList.length > 0 && (
        <Section title="Saran & Rekomendasi">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {suggestionList.map((s: any, i: number) => (
              <div key={i} style={{
                display: 'flex', gap: 12, padding: '12px 16px',
                background: 'var(--color-primary-subtle)', borderRadius: 8,
              }}>
                <Lightbulb size={18} style={{ color: 'var(--color-primary)', flexShrink: 0, marginTop: 1 }} />
                <span style={{ fontSize: 'var(--font-sm)' }}>{s.message || s.text || JSON.stringify(s)}</span>
              </div>
            ))}
          </div>
        </Section>
      )}

      {/* Revenue + Costs link to sub-pages if needed */}
      <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
        <button
          onClick={() => window.location.href = '/dashboard/finance/reports'}
          style={{ padding: '8px 16px', borderRadius: 8, border: '1px solid var(--color-border)', background: 'var(--color-surface)', cursor: 'pointer', fontSize: 'var(--font-sm)', display: 'flex', alignItems: 'center', gap: 6 }}
        >
          <TrendingUp size={14} /> Laporan Keuangan
        </button>
      </div>
    </div>
  )
}
