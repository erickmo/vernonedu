import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { financeReportsService } from '@/services/finance-reports.service'

const currencyFmt = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 })
const fmt = (n: number | undefined) => n != null ? currencyFmt.format(n) : '—'

function ReportSection({ title, rows, total }: {
  title: string
  rows: Array<{ label: string; amount: number; [k: string]: unknown }>
  total?: number
}) {
  return (
    <div style={{ marginBottom: 32 }}>
      <div style={{
        fontWeight: 700, fontSize: 'var(--font-base)',
        padding: '10px 16px',
        background: 'var(--color-surface-alt)',
        borderRadius: '8px 8px 0 0',
        borderBottom: '2px solid var(--color-border)',
      }}>{title}</div>
      {rows.map((row, i) => (
        <div key={i} style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '10px 16px',
          borderBottom: '1px solid var(--color-border)',
          background: 'var(--color-surface)',
          fontSize: 'var(--font-sm)',
        }}>
          <span>{row.label || (row as any).name || `Row ${i + 1}`}</span>
          <span style={{ fontWeight: 500 }}>{fmt(row.amount)}</span>
        </div>
      ))}
      {total != null && (
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          padding: '12px 16px',
          background: 'var(--color-primary-subtle)',
          borderRadius: '0 0 8px 8px',
          fontWeight: 700,
        }}>
          <span>Total {title}</span>
          <span>{fmt(total)}</span>
        </div>
      )}
    </div>
  )
}

export default function BalanceSheetPage() {
  const now = new Date()
  const [period, setPeriod] = useState(
    `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
  )

  const { data, isLoading, error } = useQuery({
    queryKey: ['finance/reports/balance-sheet', period],
    queryFn: () => financeReportsService.getBalanceSheet({ period }),
  })

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 28 }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, margin: 0 }}>Neraca Keuangan</h1>
        <input
          type="month"
          value={period}
          onChange={e => setPeriod(e.target.value)}
          style={{ padding: '6px 12px', border: '1px solid var(--color-border)', borderRadius: 8, fontSize: 'var(--font-sm)' }}
        />
      </div>

      {isLoading && <div style={{ color: 'var(--color-text-secondary)' }}>Memuat data...</div>}
      {error && <div style={{ color: 'var(--color-error)' }}>Gagal memuat laporan. Coba lagi.</div>}

      {data && (
        <div style={{ maxWidth: 800 }}>
          {data.assets?.items && (
            <ReportSection title="Aset" rows={data.assets.items} total={data.assets?.total} />
          )}
          {data.liabilities?.items && (
            <ReportSection title="Liabilitas" rows={data.liabilities.items} total={data.liabilities?.total} />
          )}
          {data.equity?.items && (
            <ReportSection title="Ekuitas" rows={data.equity.items} total={data.equity?.total} />
          )}
          {!data.assets && !data.liabilities && !data.equity && (
            <pre style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-secondary)', background: 'var(--color-surface-alt)', padding: 16, borderRadius: 8, overflow: 'auto' }}>
              {JSON.stringify(data, null, 2)}
            </pre>
          )}
        </div>
      )}
    </div>
  )
}
