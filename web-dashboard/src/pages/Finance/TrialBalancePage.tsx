import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { financeReportsService } from '@/services/finance-reports.service'

const currencyFmt = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 })
const fmt = (n: number | undefined) => n != null ? currencyFmt.format(n) : '—'

export default function TrialBalancePage() {
  const now = new Date()
  const [period, setPeriod] = useState(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`)

  const { data, isLoading, error } = useQuery({
    queryKey: ['finance/reports/trial-balance', period],
    queryFn: () => financeReportsService.getTrialBalance({ period }),
  })

  const accounts: any[] = Array.isArray(data)
    ? data
    : (data?.accounts ?? data?.data ?? data?.rows ?? [])

  const totalDebit = data?.total_debit ?? accounts.reduce((sum: number, a: any) => sum + (a.debit ?? 0), 0)
  const totalCredit = data?.total_credit ?? accounts.reduce((sum: number, a: any) => sum + (a.credit ?? 0), 0)

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 28 }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, margin: 0 }}>Neraca Saldo</h1>
        <input type="month" value={period} onChange={e => setPeriod(e.target.value)}
          style={{ padding: '6px 12px', border: '1px solid var(--color-border)', borderRadius: 8, fontSize: 'var(--font-sm)' }} />
      </div>

      {isLoading && <div style={{ color: 'var(--color-text-secondary)' }}>Memuat data...</div>}
      {error && <div style={{ color: 'var(--color-error)' }}>Gagal memuat laporan.</div>}

      {data && (
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)', maxWidth: 800 }}>
          <thead>
            <tr style={{ background: 'var(--color-surface-alt)' }}>
              {['Kode', 'Nama Akun', 'Debit', 'Kredit'].map(h => (
                <th key={h} style={{ padding: '10px 12px', borderBottom: '2px solid var(--color-border)', textAlign: h === 'Debit' || h === 'Kredit' ? 'right' : 'left', fontWeight: 600 }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {accounts.length === 0 && (
              <tr><td colSpan={4} style={{ textAlign: 'center', padding: 24, color: 'var(--color-text-tertiary)' }}>Tidak ada data</td></tr>
            )}
            {accounts.map((acc: any, i: number) => (
              <tr key={i} style={{ borderBottom: '1px solid var(--color-border)' }}>
                <td style={{ padding: '9px 12px', fontFamily: 'monospace' }}>{acc.code || acc.account_code || '—'}</td>
                <td style={{ padding: '9px 12px' }}>{acc.name || acc.account_name || '—'}</td>
                <td style={{ padding: '9px 12px', textAlign: 'right' }}>{acc.debit ? fmt(acc.debit) : '—'}</td>
                <td style={{ padding: '9px 12px', textAlign: 'right' }}>{acc.credit ? fmt(acc.credit) : '—'}</td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr style={{ background: 'var(--color-primary-subtle)', fontWeight: 700 }}>
              <td colSpan={2} style={{ padding: '12px 12px' }}>TOTAL</td>
              <td style={{ padding: '12px 12px', textAlign: 'right' }}>{fmt(totalDebit)}</td>
              <td style={{ padding: '12px 12px', textAlign: 'right' }}>{fmt(totalCredit)}</td>
            </tr>
          </tfoot>
        </table>
      )}
    </div>
  )
}
