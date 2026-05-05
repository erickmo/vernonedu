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
