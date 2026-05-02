import { useMemo, useState } from 'react'
import { Download } from 'lucide-react'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PeriodFilter from '../PeriodFilter'
import { useTrialBalance } from '@/lib/api/finance-reports'
import { exportRowsAsCsv } from '@/lib/utils/csv'
import { formatCurrency } from '@/lib/utils/format'

export default function TrialBalance() {
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [branchId, setBranchId] = useState('')
  const { data, isLoading } = useTrialBalance({ from, to, branch_id: branchId || undefined })

  const csvRows = useMemo(
    () =>
      (data?.Lines ?? []).map((l) => [
        l.AccountCode,
        l.AccountName,
        l.AccountType,
        l.Debit,
        l.Credit,
      ]),
    [data],
  )

  const handleExport = () =>
    exportRowsAsCsv('trial-balance', ['Code', 'Name', 'Type', 'Debit', 'Credit'], csvRows)

  return (
    <div>
      <PageHeader
        title="Trial Balance"
        subtitle="Neraca percobaan"
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
        <div className="bg-white border border-neutral-200 rounded-lg p-4">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-xs text-neutral-500 border-b border-neutral-200">
                <th className="py-2">Code</th>
                <th className="py-2">Name</th>
                <th className="py-2">Type</th>
                <th className="py-2 text-right">Debit</th>
                <th className="py-2 text-right">Credit</th>
              </tr>
            </thead>
            <tbody>
              {(data?.Lines ?? []).map((l, idx) => (
                <tr key={idx} className="border-b border-neutral-100">
                  <td className="py-2 font-mono text-xs">{l.AccountCode}</td>
                  <td className="py-2">{l.AccountName}</td>
                  <td className="py-2 text-xs uppercase text-neutral-500">{l.AccountType}</td>
                  <td className="py-2 text-right font-mono">{formatCurrency(l.Debit ?? 0)}</td>
                  <td className="py-2 text-right font-mono">{formatCurrency(l.Credit ?? 0)}</td>
                </tr>
              ))}
              <tr className="font-semibold bg-neutral-50">
                <td className="py-2" colSpan={3}>
                  Totals
                </td>
                <td className="py-2 text-right font-mono">{formatCurrency(data?.TotalDebit ?? 0)}</td>
                <td className="py-2 text-right font-mono">{formatCurrency(data?.TotalCredit ?? 0)}</td>
              </tr>
            </tbody>
          </table>
          <div className="mt-3 text-sm">
            Balanced: <span className="font-semibold">{data?.IsBalanced ? 'Yes' : 'No'}</span>
          </div>
        </div>
      )}
    </div>
  )
}
