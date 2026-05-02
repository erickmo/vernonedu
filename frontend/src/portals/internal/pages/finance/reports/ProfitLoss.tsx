import { useMemo, useState } from 'react'
import { Download } from 'lucide-react'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PeriodFilter from '../PeriodFilter'
import { useProfitLoss } from '@/lib/api/finance-reports'
import { exportRowsAsCsv } from '@/lib/utils/csv'
import { formatCurrency } from '@/lib/utils/format'
import type { PLLine } from '@/types/financereport'

function PLSection({ title, lines, total }: { title: string; lines?: PLLine[]; total?: number }) {
  return (
    <div className="bg-white border border-neutral-200 rounded-lg p-4 mb-4">
      <h3 className="font-semibold text-neutral-800 mb-3">{title}</h3>
      <table className="w-full text-sm">
        <tbody>
          {(lines ?? []).map((line, idx) => (
            <tr key={idx} className="border-b border-neutral-100">
              <td className="py-2 font-mono text-xs text-neutral-600 w-24">{line.AccountCode}</td>
              <td className="py-2 text-neutral-800">{line.AccountName}</td>
              <td className="py-2 text-right font-mono">{formatCurrency(line.Amount ?? 0)}</td>
            </tr>
          ))}
          <tr className="font-semibold bg-neutral-50">
            <td className="py-2" colSpan={2}>Total {title}</td>
            <td className="py-2 text-right font-mono">{formatCurrency(total ?? 0)}</td>
          </tr>
        </tbody>
      </table>
    </div>
  )
}

export default function ProfitLoss() {
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [branchId, setBranchId] = useState('')
  const { data, isLoading } = useProfitLoss({ from, to, branch_id: branchId || undefined })

  const csvRows = useMemo(() => {
    const out: Array<Array<unknown>> = []
    const push = (group: string, lines?: PLLine[]) =>
      (lines ?? []).forEach((l) => out.push([group, l.AccountCode, l.AccountName, l.Amount]))
    push('Revenue', data?.Revenue)
    push('HPP', data?.HPP)
    push('OpExpense', data?.OpExpenses)
    return out
  }, [data])

  const handleExport = () =>
    exportRowsAsCsv('profit-loss', ['Group', 'Code', 'Name', 'Amount'], csvRows)

  return (
    <div>
      <PageHeader
        title="Profit & Loss"
        subtitle="Laporan laba rugi per periode"
        actions={
          <button
            onClick={handleExport}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-neutral-700 bg-white border border-neutral-200 rounded-lg hover:bg-neutral-50"
          >
            <Download className="w-4 h-4" /> CSV
          </button>
        }
      />
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
      {isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <>
          <PLSection title="Revenue" lines={data?.Revenue} total={data?.TotalRevenue} />
          <PLSection title="HPP" lines={data?.HPP} total={data?.TotalHPP} />
          <PLSection title="Operating Expenses" lines={data?.OpExpenses} total={data?.TotalOpExpense} />
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-4">
              <div className="text-xs text-emerald-700">Gross Profit</div>
              <div className="text-xl font-bold text-emerald-800 font-mono">
                {formatCurrency(data?.GrossProfit ?? 0)}
              </div>
            </div>
            <div className="bg-brand-50 border border-brand-200 rounded-lg p-4">
              <div className="text-xs text-brand-700">Net Profit</div>
              <div className="text-xl font-bold text-brand-800 font-mono">
                {formatCurrency(data?.NetProfit ?? 0)}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
