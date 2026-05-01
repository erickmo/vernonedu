import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { GraduationCap } from 'lucide-react'
import DetailPageLayout, { BreadcrumbItem, DetailTab } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import { useStudent } from '@/lib/api/identity'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'enrollments', label: 'Enrollments' },
  { value: 'certificates', label: 'Certificates' },
  { value: 'payments', label: 'Payments' },
  { value: 'activity', label: 'Activity' },
]

export default function StudentDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState('overview')
  const { data: student, isLoading } = useStudent(id)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-24">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (!student) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <p className="text-neutral-500">Student not found.</p>
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
    { label: 'HR', to: '/internal/hr' },
    { label: 'Students', to: '/internal/students' },
    { label: student.name },
  ]

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<GraduationCap className="w-5 h-5 text-brand-600" />}
      title={student.name}
      subtitle={student.email}
      status={<span className="text-xs px-2 py-0.5 bg-neutral-100 text-neutral-600 rounded-full capitalize">{student.source}</span>}
      tabs={TABS}
      activeTab={activeTab}
      onTabChange={setActiveTab}
    >
      {activeTab === 'overview' && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Email</p>
            <p className="text-sm font-semibold text-neutral-900 break-all">{student.email}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Phone</p>
            <p className="text-sm font-semibold text-neutral-900">{student.phone}</p>
          </div>
          <div className="bg-white rounded-xl border border-neutral-100 p-4">
            <p className="text-xs text-neutral-400 mb-1">Source</p>
            <p className="text-sm font-semibold text-neutral-900 uppercase">{student.source}</p>
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
