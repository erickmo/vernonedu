import { useMemo, useState } from 'react'
import { Download } from 'lucide-react'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PeriodFilter from '../PeriodFilter'
import { useBalanceSheet } from '@/lib/api/finance-reports'
import { exportRowsAsCsv } from '@/lib/utils/csv'
import { formatCurrency } from '@/lib/utils/format'
import type { BalanceSheetLine } from '@/types/financereport'

const SECTION_HEADERS = ['Account Code', 'Account Name', 'Balance']

function Section({ title, lines, total }: { title: string; lines?: BalanceSheetLine[]; total?: number }) {
  return (
    <div className="bg-white border border-neutral-200 rounded-lg p-4 mb-4">
      <h3 className="font-semibold text-neutral-800 mb-3">{title}</h3>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-xs text-neutral-500 border-b border-neutral-200">
            {SECTION_HEADERS.map((h) => (
              <th key={h} className="py-2 font-medium">{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {(lines ?? []).map((line, idx) => (
            <tr key={idx} className="border-b border-neutral-100">
              <td className="py-2 font-mono text-xs text-neutral-600">{line.AccountCode}</td>
              <td className="py-2 text-neutral-800">{line.AccountName}</td>
              <td className="py-2 text-right font-mono">{formatCurrency(line.Balance ?? 0)}</td>
            </tr>
          ))}
          <tr className="font-semibold">
            <td className="py-2" colSpan={2}>Total {title}</td>
            <td className="py-2 text-right font-mono">{formatCurrency(total ?? 0)}</td>
          </tr>
        </tbody>
      </table>
    </div>
  )
}

export default function BalanceSheet() {
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [branchId, setBranchId] = useState('')
  const { data, isLoading } = useBalanceSheet({ from, to, branch_id: branchId || undefined })

  const csvRows = useMemo(() => {
    const all: Array<Array<unknown>> = []
    const push = (group: string, lines?: BalanceSheetLine[]) =>
      (lines ?? []).forEach((l) => all.push([group, l.AccountCode, l.AccountName, l.Balance]))
    push('Asset', data?.Assets)
    push('Liability', data?.Liabilities)
    push('Equity', data?.Equity)
    return all
  }, [data])

  const handleExport = () =>
    exportRowsAsCsv('balance-sheet', ['Group', 'Code', 'Name', 'Balance'], csvRows)

  return (
    <div>
      <PageHeader
        title="Balance Sheet"
        subtitle="Posisi aset, liabilitas, dan ekuitas per periode"
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
          <Section title="Assets" lines={data?.Assets} total={data?.TotalAssets} />
          <Section title="Liabilities" lines={data?.Liabilities} total={data?.TotalLiab} />
          <Section title="Equity" lines={data?.Equity} total={data?.TotalEquity} />
          <div className="bg-neutral-50 border border-neutral-200 rounded-lg p-4 text-sm">
            Balanced: <span className="font-semibold">{data?.IsBalanced ? 'Yes' : 'No'}</span>
          </div>
        </>
      )}
    </div>
  )
}
