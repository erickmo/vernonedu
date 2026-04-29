import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { TrendingUp } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'

interface ProfitSplitData {
  id: string
  course_id: string
  status: string
}

function useProfitSplitDetail(id: string): { data: ProfitSplitData; isLoading: false } {
  return {
    data: { id, course_id: id, status: 'draft' },
    isLoading: false,
  }
}

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'breakdown', label: 'Breakdown' },
  { value: 'activity', label: 'Activity' },
]

export default function ProfitSplitDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: split } = useProfitSplitDetail(id)

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Finance', to: '/internal/finance' },
    { label: 'Profit Split', to: '/internal/profit-split' },
    { label: `Split ${id?.slice(0, 8)}` },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<TrendingUp className="w-5 h-5 text-brand-600" />}
      title={`Split ${id?.slice(0, 8)}`}
      status={<StatusBadge status={split.status} />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={split.status} />
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4 col-span-2">
            <p className="text-xs text-neutral-400 mb-1">Course ID</p>
            <p className="text-xs font-mono text-neutral-700">{split.course_id}</p>
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
