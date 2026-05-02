import { useMemo, useState } from 'react'
import { Download } from 'lucide-react'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import PeriodFilter from '../PeriodFilter'
import { useGeneralLedger } from '@/lib/api/finance-reports'
import { exportRowsAsCsv } from '@/lib/utils/csv'
import { formatCurrency, formatDate } from '@/lib/utils/format'

export default function GeneralLedger() {
  const [account, setAccount] = useState('')
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [branchId, setBranchId] = useState('')
  const { data, isLoading } = useGeneralLedger(account, {
    from,
    to,
    branch_id: branchId || undefined,
  })

  const csvRows = useMemo(
    () =>
      (data?.Entries ?? []).map((e) => [
        e.Date,
        e.ReferenceNo,
        e.Description,
        e.Debit,
        e.Credit,
        e.RunningBalance,
      ]),
    [data],
  )

  const handleExport = () =>
    exportRowsAsCsv(
      `ledger-${account || 'all'}`,
      ['Date', 'Reference', 'Description', 'Debit', 'Credit', 'Running Balance'],
      csvRows,
    )

  return (
    <div>
      <PageHeader
        title="General Ledger"
        subtitle="Buku besar per akun"
        actions={
          <button
            onClick={handleExport}
            disabled={!account}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-neutral-700 bg-white border border-neutral-200 rounded-lg hover:bg-neutral-50 disabled:opacity-50"
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
          extra={
            <input
              type="text"
              placeholder="Account code (e.g. 1100)"
              value={account}
              onChange={(e) => setAccount(e.target.value)}
              className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white w-48"
            />
          }
        />
      </div>
      {!account ? (
        <div className="bg-neutral-50 border border-neutral-200 rounded-lg p-6 text-sm text-neutral-500">
          Enter an account code to view its ledger.
        </div>
      ) : isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <div className="bg-white border border-neutral-200 rounded-lg p-4">
          <div className="mb-3 text-sm">
            <span className="font-semibold">{data?.AccountCode}</span> — {data?.AccountName} ·
            Opening: <span className="font-mono">{formatCurrency(data?.OpeningBalance ?? 0)}</span>
          </div>
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-xs text-neutral-500 border-b border-neutral-200">
                <th className="py-2">Date</th>
                <th className="py-2">Ref</th>
                <th className="py-2">Description</th>
                <th className="py-2 text-right">Debit</th>
                <th className="py-2 text-right">Credit</th>
                <th className="py-2 text-right">Balance</th>
              </tr>
            </thead>
            <tbody>
              {(data?.Entries ?? []).map((e, idx) => (
                <tr key={idx} className="border-b border-neutral-100">
                  <td className="py-2 text-xs">{e.Date ? formatDate(e.Date) : '—'}</td>
                  <td className="py-2 font-mono text-xs">{e.ReferenceNo}</td>
                  <td className="py-2">{e.Description}</td>
                  <td className="py-2 text-right font-mono">{formatCurrency(e.Debit ?? 0)}</td>
                  <td className="py-2 text-right font-mono">{formatCurrency(e.Credit ?? 0)}</td>
                  <td className="py-2 text-right font-mono">
                    {formatCurrency(e.RunningBalance ?? 0)}
                  </td>
                </tr>
              ))}
              <tr className="font-semibold bg-neutral-50">
                <td className="py-2" colSpan={3}>
                  Totals
                </td>
                <td className="py-2 text-right font-mono">{formatCurrency(data?.TotalDebit ?? 0)}</td>
                <td className="py-2 text-right font-mono">
                  {formatCurrency(data?.TotalCredit ?? 0)}
                </td>
                <td className="py-2 text-right font-mono">
                  {formatCurrency(data?.ClosingBalance ?? 0)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
