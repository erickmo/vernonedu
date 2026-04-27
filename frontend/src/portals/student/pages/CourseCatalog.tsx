import { useState } from 'react'
import { Search, Calendar, Monitor, MapPin } from 'lucide-react'
import { useCourses } from '@/lib/api/catalog'
import { useDepartments } from '@/lib/api/identity'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'
import PageHeader from '@/components/shared/PageHeader'

const FORMAT_ICON = {
  online: Monitor,
  offline: MapPin,
  hybrid: Monitor,
}

export default function CourseCatalog() {
  const [search, setSearch] = useState('')
  const [departmentId, setDepartmentId] = useState('')

  const { data: departments } = useDepartments()
  const { data: coursesData, isLoading, isError } = useCourses({
    search: search || undefined,
    department_id: departmentId || undefined,
    status: 'active',
  })

  const courses = coursesData?.data ?? []

  if (isError) {
    return (
      <EmptyState
        title="Failed to load courses"
        description="Unable to fetch the course catalog. Please try again."
      />
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Course Catalog"
        subtitle="Browse available training programs"
        breadcrumbs={[{ label: 'Course Catalog' }]}
      />

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search courses..."
            className="w-full pl-9 pr-4 py-2.5 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>
        <select
          value={departmentId}
          onChange={(e) => setDepartmentId(e.target.value)}
          className="px-3 py-2.5 text-sm border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
        >
          <option value="">All departments</option>
          {(departments ?? []).map((d) => (
            <option key={d.id} value={d.id}>{d.name}</option>
          ))}
        </select>
      </div>

      {isLoading ? (
        <LoadingSpinner className="py-20" size="lg" />
      ) : courses.length === 0 ? (
        <EmptyState
          title="No courses found"
          description="Try adjusting your search or filter criteria."
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {courses.map((course) => {
            const Icon = FORMAT_ICON[course.format] ?? Monitor
            return (
              <div
                key={course.id}
                className="bg-white rounded-xl border border-border hover:shadow-md transition-shadow overflow-hidden"
              >
                <div className="h-2 bg-gradient-to-r from-brand-500 to-brand-400" />
                <div className="p-5 space-y-4">
                  <div>
                    <div className="flex items-start justify-between gap-2">
                      <h3 className="font-semibold text-neutral-900 text-sm leading-tight">{course.name}</h3>
                      <span className="shrink-0 inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-neutral-100 text-xs text-neutral-600">
                        <Icon className="w-3 h-3" />
                        {course.format}
                      </span>
                    </div>
                    <p className="text-xs text-neutral-500 mt-1 line-clamp-2">{course.description}</p>
                  </div>

                  <div className="flex items-center gap-4 text-xs text-neutral-500">
                    <span className="flex items-center gap-1">
                      <Calendar className="w-3.5 h-3.5" />
                      {course.duration_days} days
                    </span>
                  </div>

                  <div className="flex items-center justify-between pt-2 border-t border-border">
                    <p className="text-sm font-semibold text-neutral-900">
                      Starting from IDR —
                    </p>
                    <button className="px-3 py-1.5 text-xs font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors">
                      View batches
                    </button>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
