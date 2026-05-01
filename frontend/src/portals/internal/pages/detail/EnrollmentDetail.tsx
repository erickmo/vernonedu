import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { ClipboardList } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import { useEnrollment } from '@/lib/api/enrollment'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'payments', label: 'Payments' },
  { value: 'activity', label: 'Activity' },
]

export default function EnrollmentDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: enrollment, isLoading } = useEnrollment(id)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!enrollment) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <p className="text-neutral-500">Enrollment not found.</p>
        <button
          onClick={() => navigate(-1)}
          className="text-sm text-brand-600 hover:underline"
        >
          Go back
        </button>
      </div>
    )
  }

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Academic', to: '/internal/academic' },
    { label: 'Enrollments', to: '/internal/enrollments' },
    { label: `Enrollment #${id.slice(0, 8)}` },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<ClipboardList className="w-5 h-5 text-brand-600" />}
      title={`Enrollment #${id.slice(0, 8)}`}
      status={<StatusBadge status={enrollment.status} />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Student ID</p>
            <p className="text-xs font-mono text-neutral-700 break-all">{enrollment.student_id}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Batch ID</p>
            <p className="text-xs font-mono text-neutral-700 break-all">{enrollment.batch_id}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={enrollment.status} />
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Completion</p>
            <p className="text-xl font-bold text-neutral-900">{enrollment.completion_percent}%</p>
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
