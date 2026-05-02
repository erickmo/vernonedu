import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { BookOpen, Edit } from 'lucide-react'
import DetailPageLayout, { type DetailTab, type BreadcrumbItem } from '@/components/layout/DetailPageLayout'
import VariantsTab from '@/portals/internal/components/curriculum/VariantsTab'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { useMasterCourse } from '@/lib/api/curriculum'

const TABS: DetailTab[] = [
  { value: 'overview', label: 'Overview' },
  { value: 'variants', label: 'Variants' },
  { value: 'versions', label: 'Versions' },
  { value: 'cert', label: 'Certificate' },
  { value: 'settings', label: 'Settings' },
]

export default function CourseDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useMasterCourse(id)
  const [tab, setTab] = useState('overview')

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Academic', to: '/internal/academic' },
    { label: 'Courses', to: '/internal/courses' },
    { label: data.course_code },
  ]

  function handleTabChange(v: string) {
    if (v === 'overview' || v === 'variants') setTab(v)
    // versions/cert/settings remain disabled until iter 1C/1D/1E
  }

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<BookOpen className="w-5 h-5 text-brand-600" />}
      title={`${data.course_code} · ${data.course_name}`}
      subtitle={`Field: ${data.field}`}
      status={<StatusBadge status={data.status} />}
      actions={
        <RoleGate action="update" resource="mastercourse">
          <Button onClick={() => navigate(`/internal/courses/${id}/edit`)}>
            <Edit className="w-4 h-4" /> Edit
          </Button>
        </RoleGate>
      }
      tabs={TABS}
      activeTab={tab}
      onTabChange={handleTabChange}
    >
      {tab === 'overview' && (
        <div className="space-y-6 max-w-3xl">
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Description</h3>
            <p className="text-sm text-neutral-700 whitespace-pre-wrap">
              {data.description || '—'}
            </p>
          </section>

          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-2">Core Competencies</h3>
            {data.core_competencies.length === 0 ? (
              <p className="text-sm text-neutral-400">—</p>
            ) : (
              <div className="flex flex-wrap gap-1.5">
                {data.core_competencies.map((c, i) => (
                  <span key={`${c}-${i}`} className="px-2 py-0.5 text-xs bg-neutral-100 text-neutral-700 rounded-full">
                    {c}
                  </span>
                ))}
              </div>
            )}
          </section>

          {data.supporting_app_url && (
            <section>
              <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Supporting App</h3>
              <a
                href={data.supporting_app_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-brand-600 hover:underline"
              >
                {data.supporting_app_url}
              </a>
            </section>
          )}

          <section className="pt-4 border-t border-neutral-100 text-xs text-neutral-500">
            Created: {new Date(data.created_at).toLocaleDateString()} ·
            Updated: {new Date(data.updated_at).toLocaleDateString()}
          </section>
        </div>
      )}
      {tab === 'variants' && <VariantsTab courseId={id} />}
    </DetailPageLayout>
  )
}
