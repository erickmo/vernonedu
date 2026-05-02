import { useState } from 'react'
import { AlertTriangle, Lightbulb, TrendingUp } from 'lucide-react'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PeriodFilter from './PeriodFilter'
import {
  useFinancialRatios,
  useRevenueAnalysis,
  useCostAnalysis,
  useBatchProfitability,
  useCashForecast,
  useFinancialAlerts,
  useFinancialSuggestions,
} from '@/lib/api/finance-analysis'
import { formatCurrency, formatPercent } from '@/lib/utils/format'
import type { RatioMetric } from '@/types/financereport'

const FORECAST_DEFAULT_MONTHS = 6
const BATCH_PROFIT_LIMIT = 10

function RatioCard({ label, metric, isPercent }: { label: string; metric?: RatioMetric; isPercent?: boolean }) {
  const value = metric?.current ?? 0
  return (
    <div className="bg-white border border-neutral-200 rounded-lg p-3">
      <div className="text-xs text-neutral-500">{label}</div>
      <div className="mt-1 text-lg font-semibold font-mono">
        {isPercent ? formatPercent(value) : formatCurrency(value)}
      </div>
      {metric?.change_pct !== undefined && (
        <div className="text-xs text-neutral-500">
          {metric.change_pct >= 0 ? '+' : ''}
          {metric.change_pct.toFixed(1)}% vs prev
        </div>
      )}
    </div>
  )
}

export default function Analysis() {
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [branchId, setBranchId] = useState('')

  const filter = { from, to, branch_id: branchId || undefined }
  const { data: ratios, isLoading: ratiosLoading } = useFinancialRatios(filter)
  const { data: revenue } = useRevenueAnalysis({ ...filter, group_by: 'course_type' })
  const { data: costs } = useCostAnalysis({ ...filter, group_by: 'category' })
  const { data: batchProfit } = useBatchProfitability({
    ...filter,
    sort: 'top',
    limit: BATCH_PROFIT_LIMIT,
  })
  const { data: forecast } = useCashForecast({
    months: FORECAST_DEFAULT_MONTHS,
    branch_id: branchId || undefined,
  })
  const { data: alerts } = useFinancialAlerts()
  const { data: suggestions } = useFinancialSuggestions()

  return (
    <div>
      <PageHeader title="Financial Analysis" subtitle="Ratios, trends, batch profitability, cash forecast" />
      <div className="mb-4">
        <PeriodFilter
          from={from}
          to={to}
          branchId={branchId}
          onFromChange={setFrom}
          onToChange={setTo}
          onBranchChange={setBranchId}
        />
      </div>

      {/* Ratios */}
      <div className="mb-6">
        <h3 className="font-semibold text-neutral-800 mb-2 flex items-center gap-1">
          <TrendingUp className="w-4 h-4" /> Key Ratios
        </h3>
        {ratiosLoading ? (
          <LoadingSpinner />
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <RatioCard label="Profit Margin" metric={ratios?.profit_margin} isPercent />
            <RatioCard label="Expense Ratio" metric={ratios?.expense_ratio} isPercent />
            <RatioCard label="Revenue / Student" metric={ratios?.revenue_per_student} />
            <RatioCard label="Cost / Student" metric={ratios?.cost_per_student} />
            <RatioCard label="Avg Batch Profit" metric={ratios?.avg_batch_profitability} isPercent />
            <RatioCard label="Collection Rate" metric={ratios?.collection_rate} isPercent />
            <RatioCard label="DSO (days)" metric={ratios?.days_sales_outstanding} />
            <RatioCard label="Revenue Growth" metric={ratios?.revenue_growth_rate} isPercent />
          </div>
        )}
      </div>

      {/* Alerts + Suggestions */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div className="bg-white border border-neutral-200 rounded-lg p-4">
          <h3 className="font-semibold text-neutral-800 mb-2 flex items-center gap-1">
            <AlertTriangle className="w-4 h-4 text-amber-500" /> Alerts
          </h3>
          {(alerts ?? []).length === 0 ? (
            <div className="text-sm text-neutral-500">No alerts.</div>
          ) : (
            <ul className="space-y-2">
              {(alerts ?? []).map((a, idx) => (
                <li key={idx} className="text-sm border-l-2 border-amber-300 pl-2">
                  <span className="font-medium">{a.code}</span> — {a.message}
                  {a.amount ? ` (${formatCurrency(a.amount)})` : ''}
                </li>
              ))}
            </ul>
          )}
        </div>
        <div className="bg-white border border-neutral-200 rounded-lg p-4">
          <h3 className="font-semibold text-neutral-800 mb-2 flex items-center gap-1">
            <Lightbulb className="w-4 h-4 text-brand-500" /> Suggestions
          </h3>
          {(suggestions ?? []).length === 0 ? (
            <div className="text-sm text-neutral-500">No suggestions.</div>
          ) : (
            <ul className="space-y-2">
              {(suggestions ?? []).map((s, idx) => (
                <li key={idx} className="text-sm">
                  {s.icon ? `${s.icon} ` : ''}
                  {s.message}
                  {s.detail ? <span className="text-neutral-500"> — {s.detail}</span> : null}
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>

      {/* Revenue & Costs by group */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div className="bg-white border border-neutral-200 rounded-lg p-4">
          <h3 className="font-semibold text-neutral-800 mb-2">Revenue by Group</h3>
          <div className="text-xs text-neutral-500 mb-2">
            Total: {formatCurrency(revenue?.total_revenue ?? 0)}
          </div>
          <table className="w-full text-sm">
            <tbody>
              {(revenue?.by_group ?? []).map((g, idx) => (
                <tr key={idx} className="border-b border-neutral-100">
                  <td className="py-1.5">{g.group_key}</td>
                  <td className="py-1.5 text-right font-mono">{formatCurrency(g.revenue ?? 0)}</td>
                  <td className="py-1.5 text-right text-xs text-neutral-500">
                    {formatPercent(g.pct_of_total ?? 0)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="bg-white border border-neutral-200 rounded-lg p-4">
          <h3 className="font-semibold text-neutral-800 mb-2">Cost by Category</h3>
          <div className="text-xs text-neutral-500 mb-2">
            Total: {formatCurrency(costs?.total_cost ?? 0)}
          </div>
          <table className="w-full text-sm">
            <tbody>
              {(costs?.by_category ?? []).map((c, idx) => (
                <tr key={idx} className="border-b border-neutral-100">
                  <td className="py-1.5">{c.category}</td>
                  <td className="py-1.5 text-right font-mono">{formatCurrency(c.amount ?? 0)}</td>
                  <td className="py-1.5 text-right text-xs text-neutral-500">
                    {formatPercent(c.pct_of_total ?? 0)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Batch profitability top 10 */}
      <div className="bg-white border border-neutral-200 rounded-lg p-4 mb-6">
        <h3 className="font-semibold text-neutral-800 mb-2">Top {BATCH_PROFIT_LIMIT} Batch Profit</h3>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-xs text-neutral-500 border-b">
              <th className="py-2">Batch</th>
              <th className="py-2">Course</th>
              <th className="py-2 text-right">Revenue</th>
              <th className="py-2 text-right">Expense</th>
              <th className="py-2 text-right">Profit</th>
              <th className="py-2 text-right">Margin</th>
            </tr>
          </thead>
          <tbody>
            {(batchProfit?.items ?? []).map((b) => (
              <tr key={b.batch_id} className="border-b border-neutral-100">
                <td className="py-1.5 font-mono text-xs">{b.batch_code}</td>
                <td className="py-1.5">{b.course_name}</td>
                <td className="py-1.5 text-right font-mono">{formatCurrency(b.revenue ?? 0)}</td>
                <td className="py-1.5 text-right font-mono">{formatCurrency(b.expense ?? 0)}</td>
                <td className="py-1.5 text-right font-mono">{formatCurrency(b.profit ?? 0)}</td>
                <td className="py-1.5 text-right">{formatPercent(b.margin_pct ?? 0)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Cash forecast */}
      <div className="bg-white border border-neutral-200 rounded-lg p-4">
        <h3 className="font-semibold text-neutral-800 mb-2">
          Cash Forecast — next {FORECAST_DEFAULT_MONTHS} months
        </h3>
        <div className="text-xs text-neutral-500 mb-2">
          Current cash: {formatCurrency(forecast?.current_cash ?? 0)}
        </div>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-xs text-neutral-500 border-b">
              <th className="py-2">Month</th>
              <th className="py-2 text-right">Opening</th>
              <th className="py-2 text-right">Inflow</th>
              <th className="py-2 text-right">Outflow</th>
              <th className="py-2 text-right">Closing</th>
            </tr>
          </thead>
          <tbody>
            {(forecast?.months ?? []).map((m) => (
              <tr key={m.month} className="border-b border-neutral-100">
                <td className="py-1.5">{m.month}</td>
                <td className="py-1.5 text-right font-mono">{formatCurrency(m.opening_cash ?? 0)}</td>
                <td className="py-1.5 text-right font-mono text-emerald-700">
                  {formatCurrency(m.inflow ?? 0)}
                </td>
                <td className="py-1.5 text-right font-mono text-rose-700">
                  {formatCurrency(m.outflow ?? 0)}
                </td>
                <td className="py-1.5 text-right font-mono">{formatCurrency(m.closing_cash ?? 0)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
