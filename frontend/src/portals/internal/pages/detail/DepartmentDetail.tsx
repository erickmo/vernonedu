import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { Building } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import StatusBadge from '@/components/shared/StatusBadge'

interface DepartmentData {
  id: string
  name: string
  code: string
  status: string
}

function useDepartmentDetail(id: string): { data: DepartmentData; isLoading: false } {
  return {
    data: {
      id,
      name: 'Department',
      code: id?.slice(0, 6).toUpperCase() ?? '',
      status: 'active',
    },
    isLoading: false,
  }
}

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'team-members', label: 'Team Members' },
  { value: 'courses', label: 'Courses' },
  { value: 'budget', label: 'Budget' },
  { value: 'activity', label: 'Activity' },
]

export default function DepartmentDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: department } = useDepartmentDetail(id)

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'HR', to: '/internal/hr' },
    { label: 'Departments', to: '/internal/departments' },
    { label: department.name },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Building className="w-5 h-5 text-brand-600" />}
      title={department.name}
      subtitle={`Code: ${department.code}`}
      status={<StatusBadge status={department.status} />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Code</p>
            <p className="text-sm font-bold font-mono text-neutral-900">{department.code}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={department.status} />
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
