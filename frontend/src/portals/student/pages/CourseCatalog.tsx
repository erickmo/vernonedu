import { useState } from 'react'
import { Search, Calendar, Monitor, MapPin, Layers } from 'lucide-react'
import { useCourses } from '@/lib/api/catalog'
import { useDepartments } from '@/lib/api/identity'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'

const FORMAT_ICON = {
  online: Monitor,
  offline: MapPin,
  hybrid: Layers,
} as const

const FORMAT_COLOR = {
  online: 'bg-brand-50 text-brand-700',
  offline: 'bg-amber-50 text-amber-700',
  hybrid: 'bg-violet-50 text-violet-700',
} as const

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
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Course Catalog</h1>
        <p className="text-sm text-neutral-500 mt-0.5">Browse available training programs</p>
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search courses…"
            className="w-full pl-9 pr-4 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
          />
        </div>
        <select
          value={departmentId}
          onChange={(e) => setDepartmentId(e.target.value)}
          className="px-3 py-2.5 text-sm border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white"
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
            const fmtColor = FORMAT_COLOR[course.format] ?? 'bg-neutral-100 text-neutral-600'
            return (
              <div
                key={course.id}
                className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] hover:shadow-md transition-shadow overflow-hidden group"
              >
                <div className="h-1.5 bg-gradient-to-r from-brand-500 to-brand-400 group-hover:from-brand-600 group-hover:to-violet-500 transition-all duration-300" />
                <div className="p-5 space-y-3">
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="font-semibold text-neutral-900 text-sm leading-snug">
                      {course.name}
                    </h3>
                    <span
                      className={`shrink-0 inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${fmtColor}`}
                    >
                      <Icon className="w-3 h-3" />
                      {course.format}
                    </span>
                  </div>

                  <p className="text-xs text-neutral-500 line-clamp-2 leading-relaxed">
                    {course.description}
                  </p>

                  <div className="flex items-center gap-3 text-xs text-neutral-500 pt-1">
                    <span className="flex items-center gap-1 font-mono">
                      <Calendar className="w-3.5 h-3.5" />
                      {course.duration_days}d
                    </span>
                    <span className="font-mono text-neutral-300">·</span>
                    <span className="font-mono">{course.code}</span>
                  </div>

                  <div className="pt-2 border-t border-neutral-50">
                    <button className="w-full py-2 text-xs font-semibold text-brand-600 hover:text-brand-700 hover:bg-brand-50 rounded-lg transition-colors">
                      View batches →
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
