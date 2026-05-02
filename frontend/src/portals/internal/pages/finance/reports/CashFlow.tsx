import { useMemo, useState } from 'react'
import { Download } from 'lucide-react'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PeriodFilter from '../PeriodFilter'
import { useCashFlow } from '@/lib/api/finance-reports'
import { exportRowsAsCsv } from '@/lib/utils/csv'
import { formatCurrency } from '@/lib/utils/format'
import type { CashFlowLine } from '@/types/financereport'

function CFSection({ title, lines, net }: { title: string; lines?: CashFlowLine[]; net?: number }) {
  return (
    <div className="bg-white border border-neutral-200 rounded-lg p-4 mb-4">
      <h3 className="font-semibold text-neutral-800 mb-3">{title}</h3>
      <table className="w-full text-sm">
        <tbody>
          {(lines ?? []).map((line, idx) => (
            <tr key={idx} className="border-b border-neutral-100">
              <td className="py-2 text-neutral-700">{line.Description}</td>
              <td className="py-2 text-right font-mono">{formatCurrency(line.Amount ?? 0)}</td>
            </tr>
          ))}
          <tr className="font-semibold bg-neutral-50">
            <td className="py-2">Net {title}</td>
            <td className="py-2 text-right font-mono">{formatCurrency(net ?? 0)}</td>
          </tr>
        </tbody>
      </table>
    </div>
  )
}

export default function CashFlow() {
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [branchId, setBranchId] = useState('')
  const { data, isLoading } = useCashFlow({ from, to, branch_id: branchId || undefined })

  const csvRows = useMemo(() => {
    const out: Array<Array<unknown>> = []
    const push = (g: string, lines?: CashFlowLine[]) =>
      (lines ?? []).forEach((l) => out.push([g, l.Description, l.Amount]))
    push('Operating', data?.Operating)
    push('Investing', data?.Investing)
    push('Financing', data?.Financing)
    return out
  }, [data])

  const handleExport = () =>
    exportRowsAsCsv('cash-flow', ['Activity', 'Description', 'Amount'], csvRows)

  return (
    <div>
      <PageHeader
        title="Cash Flow"
        subtitle="Statement of cash flows"
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
          <CFSection title="Operating" lines={data?.Operating} net={data?.NetOperating} />
          <CFSection title="Investing" lines={data?.Investing} net={data?.NetInvesting} />
          <CFSection title="Financing" lines={data?.Financing} net={data?.NetFinancing} />
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-neutral-50 border rounded-lg p-3">
              <div className="text-xs text-neutral-500">Opening</div>
              <div className="font-mono font-semibold">{formatCurrency(data?.OpeningBalance ?? 0)}</div>
            </div>
            <div className="bg-neutral-50 border rounded-lg p-3">
              <div className="text-xs text-neutral-500">Net Change</div>
              <div className="font-mono font-semibold">{formatCurrency(data?.NetChange ?? 0)}</div>
            </div>
            <div className="bg-neutral-50 border rounded-lg p-3">
              <div className="text-xs text-neutral-500">Closing</div>
              <div className="font-mono font-semibold">{formatCurrency(data?.ClosingBalance ?? 0)}</div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
