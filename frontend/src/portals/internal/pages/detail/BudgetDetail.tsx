import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { PiggyBank } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'

interface BudgetData {
  id: string
  batch_id: string
  status: string
}

function useBudgetDetail(id: string): { data: BudgetData; isLoading: false } {
  return {
    data: { id, batch_id: id, status: 'active' },
    isLoading: false,
  }
}

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'transactions', label: 'Transactions' },
  { value: 'activity', label: 'Activity' },
]

export default function BudgetDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: budget } = useBudgetDetail(id)

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Finance', to: '/internal/finance' },
    { label: 'Budget', to: '/internal/budget' },
    { label: `Budget ${id?.slice(0, 8)}` },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<PiggyBank className="w-5 h-5 text-brand-600" />}
      title={`Budget ${id?.slice(0, 8)}`}
      status={<StatusBadge status={budget.status} />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={budget.status} />
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4 col-span-2">
            <p className="text-xs text-neutral-400 mb-1">Batch ID</p>
            <p className="text-xs font-mono text-neutral-700">{budget.batch_id}</p>
          </div>
        </div>
      )}

      {activeTab !== 'overview' && (
        <div className="py-12 text-center text-neutral-400 text-sm">
          {TABS.find(t => t.value === activeTab)?.label} — coming in next sprint
        </div>
      )}
    </DetailPageLayout>
  )
}
