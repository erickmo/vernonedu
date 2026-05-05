import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { financeReportsService } from '@/services/finance-reports.service'

const currencyFmt = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 })
const fmt = (n: number | undefined) => n != null ? currencyFmt.format(n) : '—'

function PLSection({ title, rows, total, accent }: {
  title: string
  rows: Array<{ label: string; amount: number; [k: string]: unknown }>
  total?: number
  accent?: string
}) {
  return (
    <div style={{ marginBottom: 24 }}>
      <div style={{ fontWeight: 700, padding: '10px 16px', background: 'var(--color-surface-alt)', borderRadius: '8px 8px 0 0', borderBottom: '2px solid var(--color-border)' }}>
        {title}
      </div>
      {rows.map((row, i) => (
        <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '9px 16px', borderBottom: '1px solid var(--color-border)', background: 'var(--color-surface)', fontSize: 'var(--font-sm)' }}>
          <span>{row.label || (row as any).name || `Item ${i + 1}`}</span>
          <span style={{ fontWeight: 500 }}>{fmt(row.amount)}</span>
        </div>
      ))}
      {total != null && (
        <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 16px', background: accent ?? 'var(--color-primary-subtle)', borderRadius: '0 0 8px 8px', fontWeight: 700 }}>
          <span>Total {title}</span>
          <span>{fmt(total)}</span>
        </div>
      )}
    </div>
  )
}

export default function ProfitLossPage() {
  const now = new Date()
  const [period, setPeriod] = useState(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`)

  const { data, isLoading, error } = useQuery({
    queryKey: ['finance/reports/profit-loss', period],
    queryFn: () => financeReportsService.getProfitLoss({ period }),
  })

  const netProfit = data?.net_profit ?? data?.net_income ?? data?.profit

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 28 }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, margin: 0 }}>Laba Rugi</h1>
        <input type="month" value={period} onChange={e => setPeriod(e.target.value)}
          style={{ padding: '6px 12px', border: '1px solid var(--color-border)', borderRadius: 8, fontSize: 'var(--font-sm)' }} />
      </div>

      {isLoading && <div style={{ color: 'var(--color-text-secondary)' }}>Memuat data...</div>}
      {error && <div style={{ color: 'var(--color-error)' }}>Gagal memuat laporan.</div>}

      {data && (
        <div style={{ maxWidth: 800 }}>
          {data.revenue?.items && (
            <PLSection title="Pendapatan" rows={data.revenue.items} total={data.revenue?.total} accent="var(--color-success-light)" />
          )}
          {data.expenses?.items && (
            <PLSection title="Beban" rows={data.expenses.items} total={data.expenses?.total} accent="var(--color-error-light)" />
          )}
          {netProfit != null && (
            <div style={{
              display: 'flex', justifyContent: 'space-between', padding: '16px 20px',
              background: netProfit >= 0 ? 'var(--color-success-light)' : 'var(--color-error-light)',
              borderRadius: 12, fontWeight: 700, fontSize: 'var(--font-base)',
            }}>
              <span>Laba Bersih</span>
              <span>{fmt(netProfit)}</span>
            </div>
          )}
          {!data.revenue && !data.expenses && (
            <pre style={{ fontSize: 'var(--font-xs)', background: 'var(--color-surface-alt)', padding: 16, borderRadius: 8 }}>
              {JSON.stringify(data, null, 2)}
            </pre>
          )}
        </div>
      )}
    </div>
  )
}
