import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { Users } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'

interface TeamMemberData {
  id: string
  full_name: string
  role: string
  email: string
}

function useTeamMemberDetail(id: string): { data: TeamMemberData; isLoading: false } {
  return {
    data: { id, full_name: 'Team Member', role: '—', email: '—' },
    isLoading: false,
  }
}

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'facilitator-enrollments', label: 'Enrollments as Facilitator' },
  { value: 'activity', label: 'Activity' },
]

export default function TeamMemberDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: teamMember } = useTeamMemberDetail(id)

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'HR', to: '/internal/hr' },
    { label: 'Team Members', to: '/internal/team-members' },
    { label: teamMember.full_name },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Users className="w-5 h-5 text-brand-600" />}
      title={teamMember.full_name}
      subtitle={teamMember.role !== '—' ? teamMember.role : undefined}
      status={<StatusBadge status="active" />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Role</p>
            <p className="text-sm font-semibold text-neutral-900">{teamMember.role}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Email</p>
            <p className="text-sm text-neutral-700 break-all">{teamMember.email}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">ID</p>
            <p className="text-xs font-mono text-neutral-700">{id.slice(0, 8)}</p>
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
