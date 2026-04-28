import { TrendingUp, DollarSign, Percent, ArrowUpRight } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { formatCurrency } from '@/lib/utils/format'

const MOCK_MONTHLY_DATA = [
  { month: 'Jan', revenue: 45_000_000, royalty: 4_500_000 },
  { month: 'Feb', revenue: 52_000_000, royalty: 5_200_000 },
  { month: 'Mar', revenue: 48_000_000, royalty: 4_800_000 },
  { month: 'Apr', revenue: 61_000_000, royalty: 6_100_000 },
  { month: 'May', revenue: 55_000_000, royalty: 5_500_000 },
  { month: 'Jun', revenue: 67_000_000, royalty: 6_700_000 },
]

const CURRENT = MOCK_MONTHLY_DATA[MOCK_MONTHLY_DATA.length - 1]
const PREV = MOCK_MONTHLY_DATA[MOCK_MONTHLY_DATA.length - 2]
const REVENUE_GROWTH = (((CURRENT.revenue - PREV.revenue) / PREV.revenue) * 100).toFixed(1)

function SummaryCard({
  title,
  value,
  badge,
  icon: Icon,
  color,
}: {
  title: string
  value: string
  badge?: string
  icon: typeof TrendingUp
  color: string
}) {
  return (
    <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-neutral-500">{title}</p>
          <p className="text-2xl font-bold text-neutral-900 mt-1">{value}</p>
          {badge && (
            <div className="flex items-center gap-1 mt-1.5">
              <ArrowUpRight className="w-3.5 h-3.5 text-emerald-600" />
              <span className="text-xs font-medium text-emerald-600">{badge} vs last month</span>
            </div>
          )}
        </div>
        <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${color}`}>
          <Icon className="w-5 h-5" />
        </div>
      </div>
    </div>
  )
}

export default function FranchiseDashboard() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Franchise Dashboard</h1>
        <p className="text-neutral-500 mt-1 text-sm">Revenue and royalty overview</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <SummaryCard
          title="Revenue (This Month)"
          value={formatCurrency(CURRENT.revenue)}
          badge={`+${REVENUE_GROWTH}%`}
          icon={TrendingUp}
          color="bg-brand-100 text-brand-600"
        />
        <SummaryCard
          title="Royalty Due"
          value={formatCurrency(CURRENT.royalty)}
          icon={DollarSign}
          color="bg-amber-100 text-amber-600"
        />
        <SummaryCard
          title="Royalty Rate"
          value="10%"
          icon={Percent}
          color="bg-violet-100 text-violet-600"
        />
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
        <h2 className="font-semibold text-neutral-800 mb-4">Monthly Revenue vs Royalty</h2>
        <ResponsiveContainer width="100%" height={280}>
          <BarChart data={MOCK_MONTHLY_DATA} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
            <YAxis
              tick={{ fontSize: 12, fill: '#94a3b8' }}
              axisLine={false}
              tickLine={false}
              tickFormatter={(v: number) => `${(v / 1_000_000).toFixed(0)}M`}
            />
            <Tooltip
              formatter={(value: number, name: string) => [
                formatCurrency(value),
                name === 'revenue' ? 'Revenue' : 'Royalty',
              ]}
              contentStyle={{ borderRadius: '8px', border: '1px solid #e2e8f0', fontSize: '12px' }}
            />
            <Bar dataKey="revenue" fill="#3b82f6" radius={[4, 4, 0, 0]} />
            <Bar dataKey="royalty" fill="#a78bfa" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
        <h2 className="font-semibold text-neutral-800 mb-4">Royalty Status</h2>
        <div className="space-y-3">
          {MOCK_MONTHLY_DATA.slice().reverse().map((row) => (
            <div key={row.month} className="flex items-center justify-between py-2.5 border-b border-border last:border-0">
              <div>
                <p className="text-sm font-medium text-neutral-800">{row.month} 2025</p>
                <p className="text-xs text-neutral-500">{formatCurrency(row.revenue)} revenue</p>
              </div>
              <div className="flex items-center gap-3">
                <p className="text-sm font-semibold text-neutral-800">{formatCurrency(row.royalty)}</p>
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800">
                  Paid
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
