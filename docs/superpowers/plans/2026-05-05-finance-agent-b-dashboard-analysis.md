# Finance Agent B — Dashboard + Analysis Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement `FinanceMainPage` (dashboard overview) and `FinancialAnalysisPage` (financial analysis).

**Architecture:** Both pages use `useQuery` with existing services. FinanceMainPage shows KPI cards + recent transactions. FinancialAnalysisPage shows ratios, batch profitability, cash forecast, and alerts. No CSS Modules — inline styles with CSS variables.

**Tech Stack:** React 18, TypeScript, TanStack React Query 5, `accountingService`, `financeAnalysisService`

---

## Before You Start

Read `.wolf/cerebrum.md` (Do-Not-Repeat section). Key constraints:
- VITE_API_BASE_URL already includes `/api/v1`. Service paths must NOT include `/api/v1`.
- `FinancialAnalysisPage` route is `/dashboard/finance/reports/analysis` (NOT `/dashboard/finance/analysis`).
- `accountingService` is at `@/services/accounting.service`.
- `financeAnalysisService` is at `@/services/finance-analysis.service`.

---

## Task 1: FinanceMainPage

**Files:**
- Modify: `src/pages/Finance/FinanceMainPage.tsx`

- [ ] **Step 1: Replace stub**

```tsx
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { ArrowRight, Receipt, TrendingUp, TrendingDown, Clock } from 'lucide-react'
import { accountingService } from '@/services/accounting.service'

const currencyFmt = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 })
const dateFmt = new Intl.DateTimeFormat('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
const fmt = (n: number | undefined) => n != null ? currencyFmt.format(n) : '—'
const fmtDate = (d: string | undefined) => d ? dateFmt.format(new Date(d)) : '—'

function KpiCard({ title, value, sub, icon, color, bg }: {
  title: string; value: string; sub?: string
  icon: React.ReactNode; color: string; bg: string
}) {
  return (
    <div style={{
      background: 'var(--color-surface)',
      border: '1px solid var(--color-border)',
      borderRadius: 12, padding: '20px',
      display: 'flex', gap: 16, alignItems: 'flex-start',
    }}>
      <div style={{ width: 48, height: 48, borderRadius: 12, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', color, flexShrink: 0 }}>
        {icon}
      </div>
      <div>
        <div style={{ fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)', marginBottom: 4 }}>{title}</div>
        <div style={{ fontSize: 'var(--font-xl)', fontWeight: 700 }}>{value}</div>
        {sub && <div style={{ fontSize: 'var(--font-xs)', color: 'var(--color-text-tertiary)', marginTop: 4 }}>{sub}</div>}
      </div>
    </div>
  )
}

export default function FinanceMainPage() {
  const navigate = useNavigate()
  const now = new Date()
  const month = now.getMonth() + 1
  const year = now.getFullYear()

  const { data: stats } = useQuery({
    queryKey: ['finance/stats', month, year],
    queryFn: () => accountingService.getStats(month, year),
  })

  const { data: txData } = useQuery({
    queryKey: ['finance/transactions', { limit: 10 }],
    queryFn: () => accountingService.listTransactions({ limit: 10 } as any),
  })

  const txList: any[] = Array.isArray(txData) ? txData : (txData?.items ?? txData?.data ?? [])

  const QUICK_LINKS = [
    { label: 'Transaksi Baru', path: '/dashboard/finance/transactions/new' },
    { label: 'Invoice Baru', path: '/dashboard/finance/invoices/new' },
    { label: 'Laporan Keuangan', path: '/dashboard/finance/reports' },
    { label: 'Analisis Keuangan', path: '/dashboard/finance/reports/analysis' },
  ]

  return (
    <div style={{ padding: '24px' }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, margin: '0 0 24px' }}>Keuangan</h1>

      {/* KPI Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 16, marginBottom: 32 }}>
        <KpiCard
          title="Pendapatan Bulan Ini"
          value={fmt(stats?.revenue ?? stats?.total_revenue)}
          icon={<TrendingUp size={22} />}
          color="var(--color-success)"
          bg="var(--color-success-light)"
        />
        <KpiCard
          title="Beban Bulan Ini"
          value={fmt(stats?.expenses ?? stats?.total_expenses)}
          icon={<TrendingDown size={22} />}
          color="var(--color-error)"
          bg="var(--color-error-light)"
        />
        <KpiCard
          title="Invoice Belum Lunas"
          value={String(stats?.outstanding_invoices ?? stats?.pending_invoices ?? '—')}
          sub={fmt(stats?.outstanding_amount ?? stats?.pending_amount)}
          icon={<Receipt size={22} />}
          color="var(--color-warning)"
          bg="var(--color-warning-light)"
        />
        <KpiCard
          title="Tagihan Jatuh Tempo"
          value={String(stats?.due_payables ?? stats?.overdue_payables ?? '—')}
          sub={fmt(stats?.due_amount ?? stats?.overdue_amount)}
          icon={<Clock size={22} />}
          color="var(--color-error)"
          bg="var(--color-error-light)"
        />
      </div>

      {/* Quick Links */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 32, flexWrap: 'wrap' }}>
        {QUICK_LINKS.map(link => (
          <button
            key={link.path}
            onClick={() => navigate(link.path)}
            style={{
              padding: '8px 16px', borderRadius: 8, border: '1px solid var(--color-primary)',
              background: 'transparent', color: 'var(--color-primary)',
              cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500,
              display: 'flex', alignItems: 'center', gap: 6,
            }}
          >
            {link.label} <ArrowRight size={14} />
          </button>
        ))}
      </div>

      {/* Recent Transactions */}
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h2 style={{ fontSize: 'var(--font-base)', fontWeight: 700, margin: 0 }}>Transaksi Terbaru</h2>
          <button
            onClick={() => navigate('/dashboard/finance/transactions')}
            style={{ background: 'none', border: 'none', color: 'var(--color-primary)', cursor: 'pointer', fontSize: 'var(--font-sm)', display: 'flex', alignItems: 'center', gap: 4 }}
          >
            Lihat semua <ArrowRight size={14} />
          </button>
        </div>

        <div style={{ background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: 12, overflow: 'hidden' }}>
          {txList.length === 0 && (
            <div style={{ textAlign: 'center', padding: 32, color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>
              Belum ada transaksi
            </div>
          )}
          {txList.map((tx: any, i: number) => (
            <div key={tx.id ?? i} style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              padding: '12px 16px',
              borderBottom: i < txList.length - 1 ? '1px solid var(--color-border)' : 'none',
              fontSize: 'var(--font-sm)',
            }}>
              <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 8,
                  background: tx.type === 'debit' ? 'var(--color-error-light)' : 'var(--color-success-light)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: tx.type === 'debit' ? 'var(--color-error)' : 'var(--color-success)',
                }}>
                  {tx.type === 'debit' ? <TrendingDown size={16} /> : <TrendingUp size={16} />}
                </div>
                <div>
                  <div style={{ fontWeight: 500 }}>{tx.description || tx.reference_number || 'Transaksi'}</div>
                  <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-xs)' }}>{fmtDate(tx.date)}</div>
                </div>
              </div>
              <div style={{
                fontWeight: 600,
                color: tx.type === 'debit' ? 'var(--color-error)' : 'var(--color-success)',
              }}>
                {tx.type === 'debit' ? '-' : '+'}{fmt(tx.amount ?? tx.debit ?? tx.credit)}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "FinanceMain" | head -10
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Finance/FinanceMainPage.tsx
git commit -m "feat(finance): implement FinanceMainPage dashboard"
```

---

## Task 2: FinancialAnalysisPage

**Files:**
- Modify: `src/pages/Finance/FinancialAnalysisPage.tsx`

Route: `/dashboard/finance/reports/analysis` (NOT `/dashboard/finance/analysis`)

- [ ] **Step 1: Replace stub**

```tsx
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
```

- [ ] **Step 2: Type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "FinancialAnalysis" | head -10
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Finance/FinancialAnalysisPage.tsx
git commit -m "feat(finance): implement FinancialAnalysisPage"
```

---

## Task 3: Final type check

- [ ] **Step 1: Run full TS check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -20
```
Expected: 0 errors (or only pre-existing unrelated errors from other files).

- [ ] **Step 2: Fix and commit if needed**

Fix any type errors in the 2 modified files, commit with `fix(finance): fix TS errors in dashboard/analysis pages`.
