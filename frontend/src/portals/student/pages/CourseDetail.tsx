import { useMemo } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  ArrowLeft,
  CalendarDays,
  CheckCircle2,
  Circle,
  Clock,
  GraduationCap,
  PlayCircle,
  Sparkles,
} from 'lucide-react'
import { useAuth } from '@/lib/auth/useAuth'
import { useCourse, useModules } from '@/lib/api/catalog'
import { useEnrollments } from '@/lib/api/enrollment'
import { formatPercent } from '@/lib/utils/format'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'
import StatusBadge from '@/components/shared/StatusBadge'

const RESUME_THRESHOLD = 1
const COMPLETED_THRESHOLD = 100
const FORMAT_LABELS: Record<string, string> = {
  online: 'Online',
  offline: 'In-person',
  hybrid: 'Hybrid',
}

interface ModuleProgressIndicatorProps {
  done: boolean
  active: boolean
}

function ModuleProgressIndicator({ done, active }: ModuleProgressIndicatorProps) {
  if (done) {
    return (
      <div className="w-9 h-9 rounded-full bg-emerald-100 flex items-center justify-center shrink-0">
        <CheckCircle2 className="w-5 h-5 text-emerald-600" />
      </div>
    )
  }
  if (active) {
    return (
      <div className="w-9 h-9 rounded-full bg-brand-600 flex items-center justify-center shrink-0 ring-4 ring-brand-100">
        <PlayCircle className="w-5 h-5 text-white" />
      </div>
    )
  }
  return (
    <div className="w-9 h-9 rounded-full bg-neutral-100 flex items-center justify-center shrink-0">
      <Circle className="w-4 h-4 text-neutral-400" />
    </div>
  )
}

export default function CourseDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const { user } = useAuth()

  const { data: course, isLoading: loadingCourse } = useCourse(id)
  const { data: modules, isLoading: loadingModules } = useModules(id)
  const { data: enrollmentsData } = useEnrollments({ student_id: user?.id })

  const enrollment = useMemo(() => {
    return enrollmentsData?.data.find((e) => e.batch_id?.startsWith(id) || false)
  }, [enrollmentsData, id])

  const completion = enrollment?.completion_percent ?? 0
  const sortedModules = useMemo(
    () => (modules ?? []).slice().sort((a, b) => a.order - b.order),
    [modules]
  )

  const activeIndex = useMemo(() => {
    if (sortedModules.length === 0) return -1
    const ratio = completion / COMPLETED_THRESHOLD
    return Math.min(sortedModules.length - 1, Math.floor(ratio * sortedModules.length))
  }, [sortedModules, completion])

  if (loadingCourse) return <LoadingSpinner className="py-24" size="lg" />

  if (!course) {
    return (
      <EmptyState
        title="Course not found"
        description="This course may have been removed or is not available."
      />
    )
  }

  const resumeLabel =
    completion >= COMPLETED_THRESHOLD
      ? 'Review course'
      : completion >= RESUME_THRESHOLD
        ? 'Resume learning'
        : 'Start learning'

  return (
    <div className="space-y-6">
      <Link
        to="/student/catalog"
        className="inline-flex items-center gap-1.5 text-sm text-neutral-500 hover:text-neutral-800 transition-colors"
      >
        <ArrowLeft className="w-4 h-4" />
        Back to catalog
      </Link>

      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-700 via-brand-600 to-violet-600 p-7 text-white shadow-lg">
        <div className="absolute -right-16 -top-16 w-64 h-64 rounded-full bg-white/10 blur-2xl" />
        <div className="absolute -left-10 bottom-0 w-48 h-48 rounded-full bg-violet-400/20 blur-3xl" />

        <div className="relative space-y-4">
          <div className="flex flex-wrap items-center gap-2 text-xs">
            <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full bg-white/15 backdrop-blur-sm font-medium">
              <Sparkles className="w-3 h-3" />
              {course.code}
            </span>
            <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full bg-white/15 backdrop-blur-sm">
              <Clock className="w-3 h-3" />
              {course.duration_days} days
            </span>
            <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full bg-white/15 backdrop-blur-sm">
              <CalendarDays className="w-3 h-3" />
              {FORMAT_LABELS[course.format] ?? course.format}
            </span>
          </div>

          <h1 className="text-3xl md:text-4xl font-bold leading-tight max-w-3xl">
            {course.name}
          </h1>
          <p className="text-white/80 max-w-2xl text-sm md:text-base">{course.description}</p>

          <div className="flex flex-wrap items-center gap-3 pt-2">
            {enrollment ? (
              <button
                type="button"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-white text-brand-700 font-semibold text-sm shadow-md hover:shadow-lg hover:scale-[1.02] active:scale-95 transition-all"
              >
                <PlayCircle className="w-4 h-4" />
                {resumeLabel}
              </button>
            ) : (
              <Link
                to="/student/catalog"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-white text-brand-700 font-semibold text-sm shadow-md hover:shadow-lg hover:scale-[1.02] active:scale-95 transition-all"
              >
                <GraduationCap className="w-4 h-4" />
                Enroll now
              </Link>
            )}

            {enrollment && (
              <div className="flex items-center gap-2">
                <StatusBadge status={enrollment.status} variant="enrollment" />
                <StatusBadge status={enrollment.payment_status} variant="payment" />
              </div>
            )}
          </div>
        </div>
      </div>

      {enrollment && (
        <div className="bg-white rounded-xl border border-border p-5">
          <div className="flex items-center justify-between mb-3">
            <div>
              <p className="text-sm font-semibold text-neutral-800">Your progress</p>
              <p className="text-xs text-neutral-500 mt-0.5">
                {sortedModules.length > 0
                  ? `${Math.min(activeIndex + 1, sortedModules.length)} of ${sortedModules.length} modules`
                  : 'No modules yet'}
              </p>
            </div>
            <span className="text-2xl font-bold text-brand-600 tabular-nums">
              {formatPercent(completion)}
            </span>
          </div>
          <div className="h-2.5 bg-neutral-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-brand-500 to-violet-500 rounded-full transition-all duration-700 ease-out"
              style={{ width: `${completion}%` }}
            />
          </div>
        </div>
      )}

      <div className="bg-white rounded-xl border border-border">
        <div className="px-5 py-4 border-b border-border">
          <h2 className="font-semibold text-neutral-800">Course modules</h2>
          <p className="text-xs text-neutral-500 mt-0.5">
            Work through each module sequentially to earn your certificate.
          </p>
        </div>

        {loadingModules ? (
          <LoadingSpinner className="py-12" />
        ) : sortedModules.length === 0 ? (
          <EmptyState
            title="No modules published"
            description="The instructor has not published any modules yet."
          />
        ) : (
          <ol className="divide-y divide-border">
            {sortedModules.map((mod, index) => {
              const done = index < activeIndex
              const active = index === activeIndex && !!enrollment
              return (
                <li key={mod.id} className="flex items-start gap-4 px-5 py-4">
                  <ModuleProgressIndicator done={done} active={active} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-medium text-neutral-400 tabular-nums">
                        {String(index + 1).padStart(2, '0')}
                      </span>
                      <p className="text-sm font-semibold text-neutral-800 truncate">
                        {mod.title}
                      </p>
                    </div>
                    {mod.description && (
                      <p className="text-xs text-neutral-500 mt-1 line-clamp-2">
                        {mod.description}
                      </p>
                    )}
                  </div>
                  {active && (
                    <button
                      type="button"
                      className="text-xs font-semibold text-brand-700 hover:text-brand-800 hover:underline shrink-0"
                    >
                      Continue
                    </button>
                  )}
                </li>
              )
            })}
          </ol>
        )}
      </div>
    </div>
  )
}
