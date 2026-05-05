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
