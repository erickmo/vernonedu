import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { financeReportsService } from '@/services/finance-reports.service'
import { accountingService } from '@/services/accounting.service'

const currencyFmt = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 })
const dateFmt = new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
const fmt = (n: number | undefined) => n != null ? currencyFmt.format(n) : '—'
const fmtDate = (d: string | undefined) => d ? dateFmt.format(new Date(d)) : '—'

export default function GeneralLedgerPage() {
  const now = new Date()
  const [period, setPeriod] = useState(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`)
  const [accountId, setAccountId] = useState('')

  const { data: coaData } = useQuery({
    queryKey: ['finance/coa'],
    queryFn: () => accountingService.listCoa(),
  })

  const { data, isLoading, error } = useQuery({
    queryKey: ['finance/reports/ledger', period, accountId],
    queryFn: () => financeReportsService.getLedger({ period, account_id: accountId || undefined }),
    enabled: true,
  })

  const accounts: any[] = Array.isArray(coaData) ? coaData : (coaData?.accounts ?? coaData?.data ?? [])
  const entries: any[] = Array.isArray(data) ? data : (data?.entries ?? data?.data ?? [])

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 28, flexWrap: 'wrap' }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, margin: 0 }}>Buku Besar</h1>
        <input type="month" value={period} onChange={e => setPeriod(e.target.value)}
          style={{ padding: '6px 12px', border: '1px solid var(--color-border)', borderRadius: 8, fontSize: 'var(--font-sm)' }} />
        <select value={accountId} onChange={e => setAccountId(e.target.value)}
          style={{ padding: '6px 12px', border: '1px solid var(--color-border)', borderRadius: 8, fontSize: 'var(--font-sm)', minWidth: 200 }}>
          <option value="">Semua Akun</option>
          {accounts.map((acc: any) => (
            <option key={acc.id} value={acc.id}>{acc.code} — {acc.name}</option>
          ))}
        </select>
      </div>

      {isLoading && <div style={{ color: 'var(--color-text-secondary)' }}>Memuat data...</div>}
      {error && <div style={{ color: 'var(--color-error)' }}>Gagal memuat laporan.</div>}

      {data && (
        <div>
          {data.account && (
            <div style={{ marginBottom: 16, padding: '12px 16px', background: 'var(--color-primary-subtle)', borderRadius: 8 }}>
              <strong>{data.account.code} — {data.account.name}</strong>
              {data.opening_balance != null && (
                <span style={{ marginLeft: 16, color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)' }}>
                  Saldo Awal: {fmt(data.opening_balance)}
                </span>
              )}
            </div>
          )}

          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 'var(--font-sm)' }}>
            <thead>
              <tr style={{ background: 'var(--color-surface-alt)', textAlign: 'left' }}>
                {['Tanggal', 'Deskripsi', 'Ref', 'Debit', 'Kredit', 'Saldo'].map(h => (
                  <th key={h} style={{ padding: '10px 12px', borderBottom: '2px solid var(--color-border)', fontWeight: 600 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {entries.length === 0 && (
                <tr><td colSpan={6} style={{ textAlign: 'center', padding: 24, color: 'var(--color-text-tertiary)' }}>Tidak ada entri</td></tr>
              )}
              {entries.map((e: any, i: number) => (
                <tr key={i} style={{ borderBottom: '1px solid var(--color-border)' }}>
                  <td style={{ padding: '9px 12px' }}>{fmtDate(e.date)}</td>
                  <td style={{ padding: '9px 12px' }}>{e.description || '—'}</td>
                  <td style={{ padding: '9px 12px', fontFamily: 'monospace' }}>{e.reference_number || '—'}</td>
                  <td style={{ padding: '9px 12px', textAlign: 'right' }}>{e.debit ? fmt(e.debit) : '—'}</td>
                  <td style={{ padding: '9px 12px', textAlign: 'right' }}>{e.credit ? fmt(e.credit) : '—'}</td>
                  <td style={{ padding: '9px 12px', textAlign: 'right', fontWeight: 600 }}>{fmt(e.balance)}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {data.closing_balance != null && (
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 16, padding: '12px 16px', background: 'var(--color-surface-alt)', borderRadius: '0 0 8px 8px', fontWeight: 700 }}>
              <span>Saldo Akhir:</span>
              <span>{fmt(data.closing_balance)}</span>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
