import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { FileText } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'

interface ProposalData {
  id: string
  title: string
  status: string
  proposed_by: string
  created_at: string
}

function useProposalDetail(id: string): { data: ProposalData; isLoading: false } {
  return {
    data: {
      id,
      title: 'Course Proposal',
      status: 'pending',
      proposed_by: '—',
      created_at: new Date().toISOString(),
    },
    isLoading: false,
  }
}

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'budget', label: 'Budget' },
  { value: 'activity', label: 'Activity' },
]

export default function ProposalDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: proposal } = useProposalDetail(id)

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Academic', to: '/internal/academic' },
    { label: 'Proposals', to: '/internal/proposals' },
    { label: proposal.title },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<FileText className="w-5 h-5 text-brand-600" />}
      title={proposal.title}
      status={<StatusBadge status={proposal.status} />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={proposal.status} />
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Proposed By</p>
            <p className="text-sm font-semibold text-neutral-900">{proposal.proposed_by}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4 col-span-2">
            <p className="text-xs text-neutral-400 mb-1">Created At</p>
            <p className="text-sm text-neutral-700">
              {new Date(proposal.created_at).toLocaleDateString()}
            </p>
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
