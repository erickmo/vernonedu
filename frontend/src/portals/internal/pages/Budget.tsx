import { useState } from 'react'
import { toast } from 'sonner'
import {
  useBatchBudgetSummary,
  useBatchBudgetItems,
  useCreateBatchBudgetItem,
} from '@/lib/api/academic'
import { formatCurrency } from '@/lib/utils/format'
import PageHeader from '@/components/shared/PageHeader'

type Tab = 'summary' | 'items'

export default function Budget() {
  const [tab, setTab] = useState<Tab>('summary')
  const [batchId, setBatchId] = useState('')
  const [inputId, setInputId] = useState('')

  const { data: summary, isLoading: summaryLoading } = useBatchBudgetSummary(batchId)
  const { data: items = [], isLoading: itemsLoading } = useBatchBudgetItems(batchId)
  const createItem = useCreateBatchBudgetItem(batchId)

  const [newLabel, setNewLabel] = useState('')
  const [newAmount, setNewAmount] = useState('')

  const handleLookup = () => {
    if (inputId.trim()) setBatchId(inputId.trim())
  }

  const handleCreateItem = async () => {
    if (!newLabel || !newAmount) return
    try {
      await createItem.mutateAsync({
        label: newLabel,
        planned_amount: parseFloat(newAmount),
      })
      toast.success('Budget item added')
      setNewLabel('')
      setNewAmount('')
    } catch {
      toast.error('Failed to add item')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Budget"
        subtitle="Batch budget items and realizations"
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4">
        <label className="block text-sm font-medium text-neutral-700 mb-2">Batch ID</label>
        <div className="flex gap-2">
          <input
            value={inputId}
            onChange={(e) => setInputId(e.target.value)}
            placeholder="Paste batch UUID…"
            className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
          <button
            onClick={handleLookup}
            className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700"
          >
            Load
          </button>
        </div>
      </div>

      {batchId && (
        <>
          <div className="flex gap-2">
            {(['summary', 'items'] as Tab[]).map((t) => (
              <button
                key={t}
                onClick={() => setTab(t)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  tab === t
                    ? 'bg-brand-600 text-white'
                    : 'bg-white border border-neutral-200 text-neutral-600 hover:bg-neutral-50'
                }`}
              >
                {t === 'summary' ? 'Summary' : 'Line Items'}
              </button>
            ))}
          </div>

          {tab === 'summary' && (
            <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6">
              {summaryLoading ? (
                <p className="text-sm text-neutral-400">Loading…</p>
              ) : summary ? (
                <div className="space-y-4">
                  <div className="grid grid-cols-3 gap-4">
                    {[
                      { label: 'Total Planned', value: summary.total_planned },
                      { label: 'Total Actual', value: summary.total_actual },
                      { label: 'Variance', value: summary.total_variance },
                    ].map(({ label, value }) => (
                      <div key={label} className="bg-neutral-50 rounded-lg p-4">
                        <p className="text-xs text-neutral-500 mb-1">{label}</p>
                        <p className="text-lg font-semibold text-neutral-900 font-mono">
                          {formatCurrency(value)}
                        </p>
                      </div>
                    ))}
                  </div>
                  <div className="divide-y divide-neutral-100">
                    {summary.items.map((row) => (
                      <div key={row.item.id} className="flex justify-between py-3">
                        <div>
                          <p className="text-sm font-medium text-neutral-800">{row.item.label}</p>
                          {row.item.category && (
                            <p className="text-xs text-neutral-400">{row.item.category}</p>
                          )}
                        </div>
                        <div className="text-right">
                          <p className="text-sm font-mono text-neutral-800">
                            {formatCurrency(row.item.planned_amount)}
                          </p>
                          <p className="text-xs text-neutral-400 font-mono">
                            actual: {formatCurrency(row.actual)}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <p className="text-sm text-neutral-400">No summary data.</p>
              )}
            </div>
          )}

          {tab === 'items' && (
            <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
              <div className="p-4 border-b border-neutral-100 flex gap-2">
                <input
                  value={newLabel}
                  onChange={(e) => setNewLabel(e.target.value)}
                  placeholder="Label"
                  className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                <input
                  value={newAmount}
                  onChange={(e) => setNewAmount(e.target.value)}
                  placeholder="Planned amount"
                  type="number"
                  className="w-36 px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                <button
                  onClick={handleCreateItem}
                  disabled={createItem.isPending}
                  className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
                >
                  Add
                </button>
              </div>
              {itemsLoading ? (
                <p className="p-4 text-sm text-neutral-400">Loading…</p>
              ) : (
                <div className="divide-y divide-neutral-100">
                  {items.map((item) => (
                    <div key={item.id} className="flex justify-between px-4 py-3">
                      <div>
                        <p className="text-sm font-medium text-neutral-800">{item.label}</p>
                        {item.category && (
                          <p className="text-xs text-neutral-400">{item.category}</p>
                        )}
                      </div>
                      <p className="text-sm font-mono text-neutral-700">
                        {formatCurrency(item.planned_amount)}
                      </p>
                    </div>
                  ))}
                  {items.length === 0 && (
                    <p className="p-4 text-sm text-neutral-400">No items yet.</p>
                  )}
                </div>
              )}
            </div>
          )}
        </>
      )}
    </div>
  )
}
