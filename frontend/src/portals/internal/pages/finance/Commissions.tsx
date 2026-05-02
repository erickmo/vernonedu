import { useEffect, useState } from 'react'
import { Save } from 'lucide-react'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import {
  useCommissionConfig,
  useUpdateCommissionConfig,
} from '@/lib/api/finance-analysis'
import type { CommissionConfig } from '@/types/financereport'

const ROLE_LABELS: Array<{ key: keyof CommissionConfig; label: string }> = [
  { key: 'course_creator_pct', label: 'Course Creator' },
  { key: 'dept_leader_pct', label: 'Department Leader' },
  { key: 'op_leader_pct', label: 'Operation Leader' },
  { key: 'facilitator_pct', label: 'Facilitator' },
]

export default function Commissions() {
  const { data, isLoading } = useCommissionConfig()
  const update = useUpdateCommissionConfig()
  const [draft, setDraft] = useState<CommissionConfig>({})

  useEffect(() => {
    if (data) setDraft(data)
  }, [data])

  const handleChange = (key: keyof CommissionConfig, value: string) => {
    const num = value === '' ? 0 : Number(value)
    setDraft((prev) => ({ ...prev, [key]: Number.isFinite(num) ? num : 0 }))
  }

  const handleSave = () => {
    update.mutate(draft)
  }

  return (
    <div>
      <PageHeader
        title="Commission Config"
        subtitle="Persentase komisi untuk peran terkait"
        actions={
          <button
            onClick={handleSave}
            disabled={update.isPending}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 disabled:opacity-50"
          >
            <Save className="w-4 h-4" /> Save
          </button>
        }
      />
      {isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <div className="bg-white border border-neutral-200 rounded-lg p-4 max-w-xl">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-xs text-neutral-500 border-b border-neutral-200">
                <th className="py-2">Role</th>
                <th className="py-2 text-right">Percentage (%)</th>
              </tr>
            </thead>
            <tbody>
              {ROLE_LABELS.map(({ key, label }) => (
                <tr key={String(key)} className="border-b border-neutral-100">
                  <td className="py-2">{label}</td>
                  <td className="py-2 text-right">
                    <input
                      type="number"
                      step="0.1"
                      min={0}
                      max={100}
                      value={Number(draft[key] ?? 0)}
                      onChange={(e) => handleChange(key, e.target.value)}
                      className="w-24 px-2 py-1 text-sm border border-neutral-200 rounded text-right font-mono"
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {update.isError && (
            <div className="mt-3 text-sm text-rose-600">Failed to save commission config.</div>
          )}
          {update.isSuccess && (
            <div className="mt-3 text-sm text-emerald-600">Saved.</div>
          )}
        </div>
      )}
    </div>
  )
}
