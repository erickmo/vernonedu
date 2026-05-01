import { GraduationCap, Clock, AlertTriangle, BookOpen, ArrowRight } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useEnrollments } from '@/lib/api/enrollment'
import { useInvoices } from '@/lib/api/finance'
import { useCourses } from '@/lib/api/catalog'
import { formatDate } from '@/lib/utils/format'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface KPICardProps {
  title: string
  value: number | string
  icon: typeof GraduationCap
  bgClass: string
  iconClass: string
  loading?: boolean
}

function KPICard({ title, value, icon: Icon, bgClass, iconClass, loading }: KPICardProps) {
  return (
    <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <p className="text-xs font-medium text-neutral-500 uppercase tracking-wide">{title}</p>
          {loading ? (
            <div className="h-9 w-20 bg-neutral-100 rounded-lg animate-pulse mt-2" />
          ) : (
            <p className="text-3xl font-bold text-neutral-900 mt-1.5 font-mono tabular-nums">{value}</p>
          )}
        </div>
        <div className={`w-11 h-11 rounded-xl flex items-center justify-center shrink-0 ${bgClass}`}>
          <Icon className={`w-5 h-5 ${iconClass}`} />
        </div>
      </div>
    </div>
  )
}

export default function InternalDashboard() {
  const { data: activeEnrollments, isLoading: l1 } = useEnrollments({ status: 'confirmed', limit: 1 })
  const { data: pendingEnrollments, isLoading: l2 } = useEnrollments({ status: 'pending', limit: 1 })
  const { data: overdueInvoices, isLoading: l3 } = useInvoices({ status: 'overdue', limit: 1 })
  const { data: openCourses, isLoading: l4 } = useCourses({ status: 'active', limit: 1 })
  const { data: recentEnrollments, isLoading: loadingRecent } = useEnrollments({ limit: 8 })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Dashboard</h1>
          <p className="text-sm text-neutral-500 mt-0.5">Operations overview</p>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <KPICard
          title="Active Enrollments"
          value={activeEnrollments?.total ?? 0}
          icon={GraduationCap}
          bgClass="bg-brand-50"
          iconClass="text-brand-600"
          loading={l1}
        />
        <KPICard
          title="Pending Confirmations"
          value={pendingEnrollments?.total ?? 0}
          icon={Clock}
          bgClass="bg-amber-50"
          iconClass="text-amber-600"
          loading={l2}
        />
        <KPICard
          title="Overdue Invoices"
          value={overdueInvoices?.total ?? 0}
          icon={AlertTriangle}
          bgClass="bg-red-50"
          iconClass="text-red-600"
          loading={l3}
        />
        <KPICard
          title="Active Courses"
          value={openCourses?.total ?? 0}
          icon={BookOpen}
          bgClass="bg-emerald-50"
          iconClass="text-emerald-600"
          loading={l4}
        />
      </div>

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4 border-b border-neutral-100">
          <div>
            <h2 className="font-semibold text-neutral-900">Recent Enrollments</h2>
            <p className="text-xs text-neutral-500 mt-0.5">Latest activity</p>
          </div>
          <Link
            to="/internal/enrollments"
            className="inline-flex items-center gap-1 text-sm font-medium text-brand-600 hover:text-brand-700 transition-colors"
          >
            View all <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>

        {loadingRecent ? (
          <LoadingSpinner className="py-12" />
        ) : (
          <ul className="divide-y divide-neutral-50">
            {(recentEnrollments?.data ?? []).map((e) => (
              <li
                key={e.id}
                className="flex items-center justify-between px-5 py-3.5 hover:bg-neutral-50/60 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-brand-50 flex items-center justify-center text-xs font-bold text-brand-700">
                    {(e.student_id ?? '?').charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <p className="text-sm font-medium text-neutral-800">{e.student_id}</p>
                    <p className="text-xs text-neutral-500">Batch {e.batch_id}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-xs text-neutral-400">{formatDate(e.enrolled_at)}</span>
                  <span
                    className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${
                      e.status === 'pending'
                        ? 'bg-amber-50 text-amber-700'
                        : e.status === 'confirmed'
                          ? 'bg-emerald-50 text-emerald-700'
                          : 'bg-neutral-100 text-neutral-500'
                    }`}
                  >
                    {e.status}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
