import { useMemo, useState } from 'react'
import { Download } from 'lucide-react'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { useBudgetVsActual } from '@/lib/api/finance-analysis'
import { exportRowsAsCsv } from '@/lib/utils/csv'
import { formatCurrency, formatPercent } from '@/lib/utils/format'

const MONTHS = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
]

function variancePct(anggaran: number, realisasi: number): number {
  if (!anggaran) return 0
  return ((realisasi - anggaran) / anggaran) * 100
}

export default function BudgetVsActual() {
  const now = new Date()
  const [month, setMonth] = useState(now.getMonth() + 1)
  const [year, setYear] = useState(now.getFullYear())
  const { data, isLoading } = useBudgetVsActual({ month, year })

  const rows = useMemo(() => data ?? [], [data])

  const csvRows = rows.map((r) => [
    r.category,
    r.is_pendapatan ? 'Pendapatan' : 'Beban',
    r.anggaran,
    r.realisasi,
    variancePct(r.anggaran ?? 0, r.realisasi ?? 0).toFixed(2),
  ])

  const handleExport = () =>
    exportRowsAsCsv(
      `budget-vs-actual-${year}-${String(month).padStart(2, '0')}`,
      ['Category', 'Type', 'Budget', 'Actual', 'Variance %'],
      csvRows,
    )

  return (
    <div>
      <PageHeader
        title="Budget vs Actual"
        subtitle="Anggaran vs realisasi per kategori"
        actions={
          <button
            onClick={handleExport}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-neutral-700 bg-white border border-neutral-200 rounded-lg hover:bg-neutral-50"
          >
            <Download className="w-4 h-4" /> CSV
          </button>
        }
      />
      <div className="mb-4 flex items-center gap-2">
        <select
          value={month}
          onChange={(e) => setMonth(Number(e.target.value))}
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
        >
          {MONTHS.map((m, idx) => (
            <option key={m} value={idx + 1}>
              {m}
            </option>
          ))}
        </select>
        <input
          type="number"
          value={year}
          onChange={(e) => setYear(Number(e.target.value))}
          className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white w-28"
        />
      </div>
      {isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <div className="bg-white border border-neutral-200 rounded-lg p-4">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-xs text-neutral-500 border-b border-neutral-200">
                <th className="py-2">Category</th>
                <th className="py-2">Type</th>
                <th className="py-2 text-right">Budget</th>
                <th className="py-2 text-right">Actual</th>
                <th className="py-2 text-right">Variance %</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r, idx) => {
                const v = variancePct(r.anggaran ?? 0, r.realisasi ?? 0)
                const overBudget = !r.is_pendapatan && v > 0
                const underRevenue = r.is_pendapatan && v < 0
                const negative = overBudget || underRevenue
                return (
                  <tr key={idx} className="border-b border-neutral-100">
                    <td className="py-1.5">{r.category}</td>
                    <td className="py-1.5 text-xs">
                      {r.is_pendapatan ? 'Pendapatan' : 'Beban'}
                    </td>
                    <td className="py-1.5 text-right font-mono">
                      {formatCurrency(r.anggaran ?? 0)}
                    </td>
                    <td className="py-1.5 text-right font-mono">
                      {formatCurrency(r.realisasi ?? 0)}
                    </td>
                    <td
                      className={`py-1.5 text-right font-mono ${negative ? 'text-rose-600' : 'text-emerald-600'}`}
                    >
                      {formatPercent(v)}
                    </td>
                  </tr>
                )
              })}
              {rows.length === 0 && (
                <tr>
                  <td colSpan={5} className="py-6 text-center text-sm text-neutral-500">
                    No data for this period.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
