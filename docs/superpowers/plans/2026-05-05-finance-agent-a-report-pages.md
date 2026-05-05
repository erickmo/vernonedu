# Finance Agent A — Report Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 6 stub Finance report pages using `financeReportsService`.

**Architecture:** Each report page = filter controls (period + optional branch_id) → `useQuery` → table display. `ReportNavigationPage` = grid of links to the 5 reports. All pages use inline styles with CSS variables (no Tailwind).

**Tech Stack:** React 18, TypeScript, TanStack React Query 5, `financeReportsService` (`@/services/finance-reports.service`)

---

## Before You Start

Read `.wolf/cerebrum.md` (Do-Not-Repeat section). Key constraints:
- VITE_API_BASE_URL already includes `/api/v1`. Service paths must NOT include `/api/v1`.
- All paths start with `/` (e.g., `/finance/reports/balance-sheet`).
- `financeReportsService` is at `src/services/finance-reports.service.ts` — DO NOT recreate it.

---

## Task 1: ReportNavigationPage

**Files:**
- Modify: `src/pages/Finance/ReportNavigationPage.tsx`

- [ ] **Step 1: Replace stub with full implementation**

```tsx
import { useNavigate } from 'react-router-dom'
import { BarChart2, TrendingUp, Droplets, BookOpen, Scale } from 'lucide-react'

const REPORTS = [
  {
    icon: Scale,
    title: 'Neraca Keuangan',
    description: 'Snapshot aset, liabilitas, dan ekuitas pada periode tertentu.',
    path: '/dashboard/finance/reports/balance-sheet',
    color: 'var(--color-primary)',
    bg: 'var(--color-primary-subtle)',
  },
  {
    icon: TrendingUp,
    title: 'Laba Rugi',
    description: 'Pendapatan vs biaya untuk menghitung net profit.',
    path: '/dashboard/finance/reports/profit-loss',
    color: 'var(--color-success)',
    bg: 'var(--color-success-light)',
  },
  {
    icon: Droplets,
    title: 'Arus Kas',
    description: 'Arus kas dari aktivitas operasi, investasi, dan pendanaan.',
    path: '/dashboard/finance/reports/cash-flow',
    color: 'var(--color-info)',
    bg: 'var(--color-info-light)',
  },
  {
    icon: BookOpen,
    title: 'Buku Besar',
    description: 'Detail mutasi per akun dengan saldo berjalan.',
    path: '/dashboard/finance/reports/general-ledger',
    color: 'var(--color-warning)',
    bg: 'var(--color-warning-light)',
  },
  {
    icon: BarChart2,
    title: 'Neraca Saldo',
    description: 'Daftar saldo semua akun untuk verifikasi keseimbangan buku.',
    path: '/dashboard/finance/reports/trial-balance',
    color: 'var(--color-error)',
    bg: 'var(--color-error-light)',
  },
]

export default function ReportNavigationPage() {
  const navigate = useNavigate()
  return (
    <div style={{ padding: '24px' }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 700, margin: '0 0 8px' }}>
        Laporan Keuangan
      </h1>
      <p style={{ color: 'var(--color-text-secondary)', margin: '0 0 32px', fontSize: 'var(--font-sm)' }}>
        Pilih laporan yang ingin ditampilkan
      </p>
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
        gap: 16,
      }}>
        {REPORTS.map(r => {
          const Icon = r.icon
          return (
            <button
              key={r.path}
              onClick={() => navigate(r.path)}
              style={{
                background: 'var(--color-surface)',
                border: '1px solid var(--color-border)',
                borderRadius: 12,
                padding: '20px',
                cursor: 'pointer',
                textAlign: 'left',
                transition: 'box-shadow 0.15s',
                display: 'flex',
                flexDirection: 'column',
                gap: 12,
              }}
              onMouseEnter={e => (e.currentTarget.style.boxShadow = 'var(--shadow-md)')}
              onMouseLeave={e => (e.currentTarget.style.boxShadow = 'none')}
            >
              <div style={{
                width: 44, height: 44, borderRadius: 10,
                background: r.bg,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: r.color,
              }}>
                <Icon size={22} />
              </div>
              <div>
                <div style={{ fontWeight: 600, fontSize: 'var(--font-base)', marginBottom: 4 }}>{r.title}</div>
                <div style={{ color: 'var(--color-text-secondary)', fontSize: 'var(--font-sm)', lineHeight: 1.5 }}>
                  {r.description}
                </div>
              </div>
            </button>
          )
        })}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep -i "ReportNavigation\|report-navigation" | head -10
```
Expected: no errors for this file.

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Finance/ReportNavigationPage.tsx
git commit -m "feat(finance): implement ReportNavigationPage"
```

---

## Task 2: BalanceSheetPage

**Files:**
- Modify: `src/pages/Finance/BalanceSheetPage.tsx`

- [ ] **Step 1: Replace stub**

```tsx
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
          <span>{row.label || row.name || `Row ${i + 1}`}</span>
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
```

- [ ] **Step 2: Type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "BalanceSheet" | head -10
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/Finance/BalanceSheetPage.tsx
git commit -m "feat(finance): implement BalanceSheetPage"
```

---

## Task 3: ProfitLossPage

**Files:**
- Modify: `src/pages/Finance/ProfitLossPage.tsx`

- [ ] **Step 1: Replace stub**

```tsx
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
          <span>{row.label || row.name || `Item ${i + 1}`}</span>
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
```

- [ ] **Step 2: Type check + commit**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "ProfitLoss" | head -5
git add web-dashboard/src/pages/Finance/ProfitLossPage.tsx
git commit -m "feat(finance): implement ProfitLossPage"
```

---

## Task 4: CashFlowPage

**Files:**
- Modify: `src/pages/Finance/CashFlowPage.tsx`

- [ ] **Step 1: Replace stub**

```tsx
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
```

- [ ] **Step 2: Type check + commit**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "CashFlow" | head -5
git add web-dashboard/src/pages/Finance/CashFlowPage.tsx
git commit -m "feat(finance): implement CashFlowPage"
```

---

## Task 5: GeneralLedgerPage

**Files:**
- Modify: `src/pages/Finance/GeneralLedgerPage.tsx`

- [ ] **Step 1: Replace stub**

```tsx
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
```

- [ ] **Step 2: Type check + commit**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "GeneralLedger" | head -5
git add web-dashboard/src/pages/Finance/GeneralLedgerPage.tsx
git commit -m "feat(finance): implement GeneralLedgerPage"
```

---

## Task 6: TrialBalancePage

**Files:**
- Modify: `src/pages/Finance/TrialBalancePage.tsx`

- [ ] **Step 1: Replace stub**

```tsx
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
```

- [ ] **Step 2: Type check + commit**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "TrialBalance" | head -5
git add web-dashboard/src/pages/Finance/TrialBalancePage.tsx
git commit -m "feat(finance): implement TrialBalancePage"
```

---

## Task 7: Final type check

- [ ] **Step 1: Run full type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -30
```
Expected: 0 errors (or only pre-existing unrelated errors).

- [ ] **Step 2: Final commit if any fixes needed**

Fix any type errors found, then commit with `fix(finance): fix TS errors in report pages`.
