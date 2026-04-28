import { useState } from 'react'
import { toast } from 'sonner'
import {
  useGlobalSettings,
  useUpdateGlobalSettings,
  useCourseOverride,
  useCreateCourseOverride,
  useAddExtraRevenue,
  useApproveExtraRevenue,
  useRejectExtraRevenue,
} from '@/lib/api/academic'
import PageHeader from '@/components/shared/PageHeader'

type Tab = 'settings' | 'overrides' | 'extra-revenue'

export default function ProfitSplit() {
  const [tab, setTab] = useState<Tab>('settings')

  const { data: settings, isLoading } = useGlobalSettings()
  const updateSettings = useUpdateGlobalSettings()
  const [settingsForm, setSettingsForm] = useState({ vernonedu_pct: '', course_creator_pct: '', dept_leader_pct: '' })

  const [overrideCourseId, setOverrideCourseId] = useState('')
  const [lookupId, setLookupId] = useState('')
  const { data: override } = useCourseOverride(overrideCourseId)
  const createOverride = useCreateCourseOverride()
  const [overrideForm, setOverrideForm] = useState({ vernonedu_pct: '', course_creator_pct: '', dept_leader_pct: '' })

  const addRevenue = useAddExtraRevenue()
  const approveRevenue = useApproveExtraRevenue()
  const rejectRevenue = useRejectExtraRevenue()
  const [revenueForm, setRevenueForm] = useState({ course_batch_id: '', label: '', amount: '' })
  const [revenueIdAction, setRevenueIdAction] = useState('')

  const handleSettingsSave = async () => {
    try {
      await updateSettings.mutateAsync(settingsForm)
      toast.success('Settings updated')
    } catch {
      toast.error('Failed to update settings')
    }
  }

  const TABS: { key: Tab; label: string }[] = [
    { key: 'settings', label: 'Global Settings' },
    { key: 'overrides', label: 'Course Overrides' },
    { key: 'extra-revenue', label: 'Extra Revenue' },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Profit Split"
        subtitle="Configure revenue distribution percentages"
      />

      <div className="flex gap-2">
        {TABS.map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              tab === key
                ? 'bg-brand-600 text-white'
                : 'bg-white border border-neutral-200 text-neutral-600 hover:bg-neutral-50'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'settings' && (
        <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6 space-y-4 max-w-md">
          {isLoading ? (
            <p className="text-sm text-neutral-400">Loading…</p>
          ) : (
            <>
              {settings && (
                <div className="text-sm text-neutral-500 space-y-1 mb-4">
                  <p>Current: VernonEdu {settings.vernonedu_pct}% / Creator {settings.course_creator_pct}% / Dept {settings.dept_leader_pct}%</p>
                </div>
              )}
              {(['vernonedu_pct', 'course_creator_pct', 'dept_leader_pct'] as const).map((field) => (
                <div key={field}>
                  <label className="block text-sm font-medium text-neutral-700 mb-1 capitalize">
                    {field.replace(/_pct$/, '').replace(/_/g, ' ')} %
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={settingsForm[field]}
                    onChange={(e) => setSettingsForm((f) => ({ ...f, [field]: e.target.value }))}
                    className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              ))}
              <button
                onClick={handleSettingsSave}
                disabled={updateSettings.isPending}
                className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
              >
                {updateSettings.isPending ? 'Saving…' : 'Save Settings'}
              </button>
            </>
          )}
        </div>
      )}

      {tab === 'overrides' && (
        <div className="space-y-4 max-w-lg">
          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4">
            <label className="block text-sm font-medium text-neutral-700 mb-2">Look up course override</label>
            <div className="flex gap-2">
              <input
                value={lookupId}
                onChange={(e) => setLookupId(e.target.value)}
                placeholder="Course UUID"
                className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
              />
              <button
                onClick={() => setOverrideCourseId(lookupId)}
                className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm hover:bg-brand-700"
              >
                Load
              </button>
            </div>
            {override && (
              <div className="mt-3 text-sm text-neutral-600 space-y-1">
                <p>VernonEdu: {override.vernonedu_pct}%</p>
                <p>Creator: {override.course_creator_pct}%</p>
                <p>Dept: {override.dept_leader_pct}%</p>
              </div>
            )}
          </div>

          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4 space-y-3">
            <h3 className="text-sm font-semibold text-neutral-700">Create Override</h3>
            <div>
              <label className="block text-xs text-neutral-500 mb-1">Course ID</label>
              <input
                value={overrideCourseId}
                placeholder="Course UUID"
                onChange={(e) => setOverrideCourseId(e.target.value)}
                className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
              />
            </div>
            {(['vernonedu_pct', 'course_creator_pct', 'dept_leader_pct'] as const).map((field) => (
              <div key={field}>
                <label className="block text-xs text-neutral-500 mb-1 capitalize">
                  {field.replace(/_pct$/, '').replace(/_/g, ' ')} %
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={overrideForm[field]}
                  onChange={(e) => setOverrideForm((f) => ({ ...f, [field]: e.target.value }))}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
              </div>
            ))}
            <button
              onClick={async () => {
                try {
                  await createOverride.mutateAsync({
                    course_id: overrideCourseId,
                    ...overrideForm,
                  })
                  toast.success('Override created')
                } catch {
                  toast.error('Failed to create override')
                }
              }}
              disabled={createOverride.isPending}
              className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
            >
              {createOverride.isPending ? 'Creating…' : 'Create Override'}
            </button>
          </div>
        </div>
      )}

      {tab === 'extra-revenue' && (
        <div className="space-y-4 max-w-lg">
          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4 space-y-3">
            <h3 className="text-sm font-semibold text-neutral-700">Add Extra Revenue</h3>
            <input
              value={revenueForm.course_batch_id}
              onChange={(e) => setRevenueForm((f) => ({ ...f, course_batch_id: e.target.value }))}
              placeholder="Batch UUID"
              className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
            />
            <input
              value={revenueForm.label}
              onChange={(e) => setRevenueForm((f) => ({ ...f, label: e.target.value }))}
              placeholder="Label"
              className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
            />
            <input
              value={revenueForm.amount}
              onChange={(e) => setRevenueForm((f) => ({ ...f, amount: e.target.value }))}
              placeholder="Amount"
              type="number"
              className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
            />
            <button
              onClick={async () => {
                try {
                  await addRevenue.mutateAsync(revenueForm)
                  toast.success('Revenue added')
                  setRevenueForm({ course_batch_id: '', label: '', amount: '' })
                } catch {
                  toast.error('Failed to add revenue')
                }
              }}
              disabled={addRevenue.isPending}
              className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
            >
              {addRevenue.isPending ? 'Adding…' : 'Add Revenue'}
            </button>
          </div>

          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4 space-y-3">
            <h3 className="text-sm font-semibold text-neutral-700">Approve / Reject Revenue</h3>
            <div className="flex gap-2">
              <input
                value={revenueIdAction}
                onChange={(e) => setRevenueIdAction(e.target.value)}
                placeholder="Revenue UUID"
                className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
              />
              <button
                onClick={() => approveRevenue.mutate(revenueIdAction, {
                  onSuccess: () => toast.success('Approved'),
                  onError: () => toast.error('Failed'),
                })}
                className="px-3 py-2 bg-emerald-600 text-white rounded-lg text-sm hover:bg-emerald-700"
              >
                Approve
              </button>
              <button
                onClick={() => rejectRevenue.mutate(revenueIdAction, {
                  onSuccess: () => toast.success('Rejected'),
                  onError: () => toast.error('Failed'),
                })}
                className="px-3 py-2 bg-red-500 text-white rounded-lg text-sm hover:bg-red-600"
              >
                Reject
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
