import { GraduationCap, Clock, AlertTriangle, BookOpen, ArrowRight, TrendingUp, TrendingDown } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useEnrollments } from '@/lib/api/enrollment'
import { useInvoices } from '@/lib/api/finance'
import { useCourses } from '@/lib/api/catalog'
import { formatDate } from '@/lib/utils/format'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/Card'
import Badge from '@/components/ui/Badge'
import Skeleton from '@/components/ui/Skeleton'
import Avatar from '@/components/ui/Avatar'
import { motion } from 'framer-motion'
import { stagger, staggerItem } from '@/lib/utils/motion'

interface KPICardProps {
  title: string
  value: number | string
  icon: typeof GraduationCap
  gradientClass: string
  iconClass: string
  loading?: boolean
  trend?: 'up' | 'down' | 'neutral'
  trendValue?: string
}

function KPICard({ title, value, icon: Icon, gradientClass, iconClass, loading, trend, trendValue }: KPICardProps) {
  return (
    <Card className="overflow-hidden hover:shadow-card-hover transition-shadow duration-300">
      <div className={`absolute inset-0 ${gradientClass} opacity-[0.03]`} />
      <CardContent className="p-5 relative">
        <div className="flex items-start justify-between gap-3">
          <div className="flex-1 min-w-0">
            <p className="text-xs font-medium text-neutral-500 uppercase tracking-wider mb-1.5">{title}</p>
            {loading ? (
              <Skeleton className="h-9 w-24 rounded-lg" />
            ) : (
              <p className="text-3xl font-bold text-neutral-900 mt-0.5 font-mono tabular-nums">{value}</p>
            )}
            {!loading && trend && trendValue && (
              <div className="flex items-center gap-1 mt-2">
                {trend === 'up' ? (
                  <TrendingUp className="w-3 h-3 text-emerald-600" />
                ) : trend === 'down' ? (
                  <TrendingDown className="w-3 h-3 text-red-600" />
                ) : null}
                <span className={`text-xs font-medium ${trend === 'up' ? 'text-emerald-600' : trend === 'down' ? 'text-red-600' : 'text-neutral-500'}`}>
                  {trendValue}
                </span>
              </div>
            )}
          </div>
          <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${gradientClass} bg-opacity-100 shadow-sm`}>
            <Icon className={`w-5 h-5 ${iconClass}`} />
          </div>
        </div>
      </CardContent>
    </Card>
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

      <motion.div
        className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4"
        variants={stagger}
        initial="hidden"
        animate="show"
      >
        <motion.div variants={staggerItem}>
          <KPICard
            title="Active Enrollments"
            value={activeEnrollments?.total ?? 0}
            icon={GraduationCap}
            gradientClass="bg-gradient-to-br from-blue-50 to-blue-100"
            iconClass="text-blue-600"
            loading={l1}
            trend="up"
            trendValue="+12%"
          />
        </motion.div>
        <motion.div variants={staggerItem}>
          <KPICard
            title="Pending Confirmations"
            value={pendingEnrollments?.total ?? 0}
            icon={Clock}
            gradientClass="bg-gradient-to-br from-amber-50 to-amber-100"
            iconClass="text-amber-600"
            loading={l2}
            trend="neutral"
            trendValue="No change"
          />
        </motion.div>
        <motion.div variants={staggerItem}>
          <KPICard
            title="Overdue Invoices"
            value={overdueInvoices?.total ?? 0}
            icon={AlertTriangle}
            gradientClass="bg-gradient-to-br from-red-50 to-red-100"
            iconClass="text-red-600"
            loading={l3}
            trend="down"
            trendValue="-5%"
          />
        </motion.div>
        <motion.div variants={staggerItem}>
          <KPICard
            title="Active Courses"
            value={openCourses?.total ?? 0}
            icon={BookOpen}
            gradientClass="bg-gradient-to-br from-emerald-50 to-emerald-100"
            iconClass="text-emerald-600"
            loading={l4}
            trend="up"
            trendValue="+3"
          />
        </motion.div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
      >
        <Card className="overflow-hidden shadow-card">
          <CardHeader className="border-b border-neutral-100">
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>Recent Enrollments</CardTitle>
                <CardDescription>Latest activity</CardDescription>
              </div>
              <Link
                to="/internal/enrollments"
                className="inline-flex items-center gap-1 text-sm font-medium text-brand-600 hover:text-brand-700 transition-colors"
              >
                View all <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </CardHeader>

          {loadingRecent ? (
            <CardContent className="py-8 space-y-3">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Skeleton className="w-10 h-10 rounded-full" />
                    <div className="space-y-1">
                      <Skeleton className="h-4 w-32" />
                      <Skeleton className="h-3 w-24" />
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Skeleton className="h-3 w-16" />
                    <Skeleton className="h-5 w-16 rounded-full" />
                  </div>
                </div>
              ))}
            </CardContent>
          ) : (
            <ul className="divide-y divide-neutral-50">
              {(recentEnrollments?.data ?? []).map((e, idx) => (
                <motion.li
                  key={e.id}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.4 + (idx * 0.05) }}
                  className="flex items-center justify-between px-5 py-3.5 hover:bg-neutral-50/80 transition-colors group"
                >
                  <div className="flex items-center gap-3">
                    <Avatar
                      fallback={(e.student_id ?? '?').charAt(0).toUpperCase()}
                      size="lg"
                    />
                    <div>
                      <p className="text-sm font-medium text-neutral-800 group-hover:text-brand-700 transition-colors">{e.student_id}</p>
                      <p className="text-xs text-neutral-500">Batch {e.batch_id}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-xs text-neutral-400 font-mono">{formatDate(e.enrolled_at)}</span>
                    <motion.div
                      initial={{ scale: 0.9, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      transition={{ delay: 0.45 + (idx * 0.05) }}
                    >
                      <Badge
                        variant={
                          e.status === 'pending'
                            ? 'warning'
                            : e.status === 'confirmed'
                              ? 'success'
                              : 'secondary'
                        }
                        className="text-xs"
                      >
                        {e.status}
                      </Badge>
                    </motion.div>
                  </div>
                </motion.li>
              ))}
            </ul>
          )}
        </Card>
      </motion.div>
    </div>
  )
}
