import { ReactNode } from 'react'

interface PeriodFilterProps {
  from: string
  to: string
  branchId: string
  onFromChange: (v: string) => void
  onToChange: (v: string) => void
  onBranchChange: (v: string) => void
  extra?: ReactNode
}

export default function PeriodFilter({
  from,
  to,
  branchId,
  onFromChange,
  onToChange,
  onBranchChange,
  extra,
}: PeriodFilterProps) {
  return (
    <div className="flex items-center gap-2 flex-wrap">
      <label className="text-xs text-neutral-500">From</label>
      <input
        type="date"
        value={from}
        onChange={(e) => onFromChange(e.target.value)}
        className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
      />
      <label className="text-xs text-neutral-500">To</label>
      <input
        type="date"
        value={to}
        onChange={(e) => onToChange(e.target.value)}
        className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white"
      />
      <input
        type="text"
        placeholder="branch_id (optional)"
        value={branchId}
        onChange={(e) => onBranchChange(e.target.value)}
        className="px-3 py-1.5 text-sm border border-neutral-200 rounded-lg bg-white w-56"
      />
      {extra}
    </div>
  )
}
