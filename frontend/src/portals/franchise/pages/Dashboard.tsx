import { TrendingUp, DollarSign, Percent, ArrowUpRight } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { formatCurrency } from '@/lib/utils/format'
import { useFranchiseeCtx } from '../FranchiseeContext'
import { useAgreement, useRoyaltyRecords, type RoyaltyRecord } from '@/lib/api/franchise'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

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

const ROYALTY_STATUS_COLORS: Record<string, string> = {
  paid: 'bg-emerald-100 text-emerald-800',
  unpaid: 'bg-amber-100 text-amber-800',
  overdue: 'bg-red-100 text-red-800',
}

function toChartData(records: RoyaltyRecord[]) {
  return records
    .slice(0, 6)
    .reverse()
    .map((r) => ({
      month: r.period,
      revenue: Number(r.gross_revenue),
      royalty: Number(r.total_royalty),
    }))
}

export default function FranchiseDashboard() {
  const { franchisee } = useFranchiseeCtx()
  const { data: agreement, isLoading: loadingAgreement } = useAgreement(franchisee.id)
  const { data: royaltyRecords = [], isLoading: loadingRoyalty } = useRoyaltyRecords(franchisee.id)

  const isLoading = loadingAgreement || loadingRoyalty

  const latest = royaltyRecords[0]
  const prev = royaltyRecords[1]
  const revenueGrowth =
    prev && latest && Number(prev.gross_revenue) > 0
      ? (((Number(latest.gross_revenue) - Number(prev.gross_revenue)) / Number(prev.gross_revenue)) * 100).toFixed(1)
      : null

  const chartData = toChartData(royaltyRecords)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">{franchisee.branch_name}</h1>
        <p className="text-neutral-500 mt-1 text-sm">Revenue and royalty overview</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <SummaryCard
          title="Revenue (Latest Period)"
          value={latest ? formatCurrency(Number(latest.gross_revenue)) : '—'}
          badge={revenueGrowth ? `+${revenueGrowth}%` : undefined}
          icon={TrendingUp}
          color="bg-brand-100 text-brand-600"
        />
        <SummaryCard
          title="Royalty Due"
          value={latest ? formatCurrency(Number(latest.total_royalty)) : '—'}
          icon={DollarSign}
          color="bg-amber-100 text-amber-600"
        />
        <SummaryCard
          title="Royalty Rate"
          value={agreement ? `${Number(agreement.revenue_royalty_pct)}%` : '—'}
          icon={Percent}
          color="bg-violet-100 text-violet-600"
        />
      </div>

      {chartData.length > 0 && (
        <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
          <h2 className="font-semibold text-neutral-800 mb-4">Monthly Revenue vs Royalty</h2>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={chartData} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
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
      )}

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
        <h2 className="font-semibold text-neutral-800 mb-4">Royalty Status</h2>
        {royaltyRecords.length === 0 ? (
          <p className="text-sm text-neutral-500 py-4 text-center">No royalty records yet.</p>
        ) : (
          <div className="space-y-3">
            {royaltyRecords.map((row) => (
              <div key={row.id} className="flex items-center justify-between py-2.5 border-b border-neutral-100 last:border-0">
                <div>
                  <p className="text-sm font-medium text-neutral-800">{row.period}</p>
                  <p className="text-xs text-neutral-500">{formatCurrency(Number(row.gross_revenue))} revenue</p>
                </div>
                <div className="flex items-center gap-3">
                  <p className="text-sm font-semibold text-neutral-800">{formatCurrency(Number(row.total_royalty))}</p>
                  <span
                    className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${ROYALTY_STATUS_COLORS[row.status] ?? 'bg-neutral-100 text-neutral-700'}`}
                  >
                    {row.status.charAt(0).toUpperCase() + row.status.slice(1)}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
