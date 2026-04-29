import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { BookOpen } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import { useCourse } from '@/lib/api/catalog'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'enrollments', label: 'Enrollments' },
  { value: 'proposals', label: 'Proposals' },
  { value: 'budget', label: 'Budget' },
  { value: 'activity', label: 'Activity' },
]

export default function CourseDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: course, isLoading } = useCourse(id)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!course) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <p className="text-neutral-500">Course not found.</p>
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
    { label: 'Courses', to: '/internal/courses' },
    { label: course.name },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<BookOpen className="w-5 h-5 text-brand-600" />}
      title={course.name}
      subtitle={`Code: ${course.code}`}
      status={<StatusBadge status={course.status} />}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Duration</p>
            <p className="text-xl font-bold text-neutral-900">{course.duration_days}</p>
            <p className="text-xs text-neutral-500 mt-0.5">days</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Format</p>
            <p className="text-sm font-semibold text-neutral-900 capitalize">{course.format}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Status</p>
            <StatusBadge status={course.status} />
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Code</p>
            <p className="text-sm font-semibold font-mono text-neutral-900">{course.code}</p>
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
