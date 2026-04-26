import { GraduationCap, Clock, AlertTriangle, BookOpen } from 'lucide-react'
import { useEnrollments } from '@/lib/api/enrollment'
import { useInvoices } from '@/lib/api/finance'
import { useCourses } from '@/lib/api/catalog'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface KPICardProps {
  title: string
  value: number | string
  icon: typeof GraduationCap
  color: string
  loading?: boolean
}

function KPICard({ title, value, icon: Icon, color, loading }: KPICardProps) {
  return (
    <div className="bg-white rounded-xl border border-border p-5">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-neutral-500">{title}</p>
          {loading ? (
            <div className="h-8 w-16 bg-neutral-200 rounded animate-pulse mt-1" />
          ) : (
            <p className="text-3xl font-bold text-neutral-900 mt-1">{value}</p>
          )}
        </div>
        <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${color}`}>
          <Icon className="w-5 h-5" />
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
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">Dashboard</h1>
        <p className="text-neutral-500 mt-1 text-sm">Operations overview</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <KPICard
          title="Active Enrollments"
          value={activeEnrollments?.total ?? 0}
          icon={GraduationCap}
          color="bg-brand-100 text-brand-600"
          loading={l1}
        />
        <KPICard
          title="Pending Confirmations"
          value={pendingEnrollments?.total ?? 0}
          icon={Clock}
          color="bg-amber-100 text-amber-600"
          loading={l2}
        />
        <KPICard
          title="Overdue Invoices"
          value={overdueInvoices?.total ?? 0}
          icon={AlertTriangle}
          color="bg-red-100 text-red-600"
          loading={l3}
        />
        <KPICard
          title="Active Courses"
          value={openCourses?.total ?? 0}
          icon={BookOpen}
          color="bg-emerald-100 text-emerald-600"
          loading={l4}
        />
      </div>

      <div className="bg-white rounded-xl border border-border">
        <div className="px-5 py-4 border-b border-border">
          <h2 className="font-semibold text-neutral-800">Recent Activity</h2>
        </div>

        {loadingRecent ? (
          <LoadingSpinner className="py-12" />
        ) : (
          <ul className="divide-y divide-border">
            {(recentEnrollments?.data ?? []).map((e) => (
              <li key={e.id} className="flex items-center justify-between px-5 py-3.5">
                <div>
                  <p className="text-sm font-medium text-neutral-800">{e.student_id}</p>
                  <p className="text-xs text-neutral-500">Batch {e.batch_id}</p>
                </div>
                <div className="flex items-center gap-2 text-xs text-neutral-500">
                  <span
                    className={
                      e.status === 'pending'
                        ? 'text-amber-600'
                        : e.status === 'confirmed'
                        ? 'text-emerald-600'
                        : 'text-neutral-400'
                    }
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
