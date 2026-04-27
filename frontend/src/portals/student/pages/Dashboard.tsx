import {
  ArrowRight,
  Award,
  BookOpen,
  Clock,
  Flame,
  Sparkles,
  TrendingUp,
} from 'lucide-react'
import { Link } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { useCertificates } from '@/lib/api/credentialing'
import { formatDate, formatPercent } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

const ACTIVE_LIMIT = 5
const RECENT_CERT_LIMIT = 3
const COMPLETION_FULL = 100
const ON_TRACK_THRESHOLD = 50

interface StatCardProps {
  label: string
  value: number | string
  hint?: string
  icon: typeof BookOpen
  accent: 'brand' | 'emerald' | 'violet' | 'amber'
}

const STAT_ACCENTS: Record<StatCardProps['accent'], { bg: string; ring: string; text: string }> = {
  brand: { bg: 'bg-brand-50', ring: 'ring-brand-100', text: 'text-brand-600' },
  emerald: { bg: 'bg-emerald-50', ring: 'ring-emerald-100', text: 'text-emerald-600' },
  violet: { bg: 'bg-violet-50', ring: 'ring-violet-100', text: 'text-violet-600' },
  amber: { bg: 'bg-amber-50', ring: 'ring-amber-100', text: 'text-amber-600' },
}

function StatCard({ label, value, hint, icon: Icon, accent }: StatCardProps) {
  const a = STAT_ACCENTS[accent]
  return (
    <div className="group relative bg-white rounded-2xl border border-border p-5 hover:shadow-md hover:-translate-y-0.5 transition-all duration-200">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-medium text-neutral-500 uppercase tracking-wide">{label}</p>
          <p className="text-3xl font-bold text-neutral-900 mt-2 tabular-nums">{value}</p>
          {hint && <p className="text-xs text-neutral-500 mt-1">{hint}</p>}
        </div>
        <div
          className={`w-11 h-11 rounded-xl ${a.bg} ring-4 ${a.ring} flex items-center justify-center group-hover:scale-110 transition-transform`}
        >
          <Icon className={`w-5 h-5 ${a.text}`} />
        </div>
      </div>
    </div>
  )
}

interface EnrollmentRowProps {
  enrollment: Enrollment
}

function EnrollmentRow({ enrollment }: EnrollmentRowProps) {
  const onTrack = enrollment.completion_percent >= ON_TRACK_THRESHOLD
  return (
    <li className="group flex items-center justify-between gap-4 px-5 py-4 hover:bg-neutral-50/60 transition-colors">
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <p className="text-sm font-semibold text-neutral-800 truncate">{enrollment.batch_id}</p>
          {onTrack && (
            <span className="inline-flex items-center gap-0.5 text-[10px] font-semibold text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded">
              <Flame className="w-2.5 h-2.5" />
              On track
            </span>
          )}
        </div>
        <p className="text-xs text-neutral-500 mt-0.5">
          Enrolled {formatDate(enrollment.enrolled_at)}
        </p>
        <div className="mt-2 flex items-center gap-2">
          <div className="flex-1 max-w-[180px] h-1.5 bg-neutral-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-brand-500 to-violet-500 rounded-full transition-all"
              style={{ width: `${enrollment.completion_percent}%` }}
            />
          </div>
          <span className="text-xs font-medium text-neutral-600 tabular-nums">
            {formatPercent(enrollment.completion_percent)}
          </span>
        </div>
      </div>
      <div className="flex items-center gap-2 shrink-0">
        <StatusBadge status={enrollment.payment_status} variant="payment" />
        <ArrowRight className="w-4 h-4 text-neutral-300 group-hover:text-brand-500 group-hover:translate-x-0.5 transition-all" />
      </div>
    </li>
  )
}

export default function StudentDashboard() {
  const { user } = useAuth()
  const { data: enrollmentsData, isLoading: loadingEnrollments } = useEnrollments({
    student_id: user?.id,
    status: 'confirmed',
    limit: ACTIVE_LIMIT,
  })
  const { data: certificates, isLoading: loadingCerts } = useCertificates(user?.id)

  const activeEnrollments = enrollmentsData?.data ?? []
  const totalEnrollments = enrollmentsData?.total ?? 0
  const certCount = certificates?.length ?? 0

  const avgCompletion =
    activeEnrollments.length === 0
      ? 0
      : activeEnrollments.reduce((sum, e) => sum + e.completion_percent, 0) /
        activeEnrollments.length

  const firstName = user?.name?.split(' ')[0] ?? 'there'
  const isCompleting = avgCompletion >= COMPLETION_FULL - 1

  return (
    <div className="space-y-6">
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-brand-700 via-brand-600 to-violet-600 px-6 py-8 md:px-10 md:py-10 text-white shadow-lg">
        <div className="absolute -top-24 -right-12 w-72 h-72 rounded-full bg-white/10 blur-3xl" />
        <div className="absolute -bottom-20 -left-10 w-56 h-56 rounded-full bg-violet-300/20 blur-3xl" />
        <div className="absolute top-6 right-6 hidden md:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/10 backdrop-blur-sm text-xs font-medium">
          <Sparkles className="w-3.5 h-3.5" />
          Keep the streak alive
        </div>

        <div className="relative max-w-2xl space-y-3">
          <p className="text-sm text-white/70 font-medium">Welcome back</p>
          <h1 className="text-3xl md:text-4xl font-bold leading-tight">
            Hi {firstName}, {isCompleting ? 'almost there!' : "let's keep learning."}
          </h1>
          <p className="text-white/80 text-sm md:text-base max-w-xl">
            {activeEnrollments.length > 0
              ? `You have ${activeEnrollments.length} active course${activeEnrollments.length === 1 ? '' : 's'} averaging ${formatPercent(avgCompletion)} completion.`
              : 'Browse the catalog to find your next learning adventure.'}
          </p>

          <div className="flex flex-wrap items-center gap-3 pt-2">
            <Link
              to="/student/catalog"
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-white text-brand-700 font-semibold text-sm shadow-md hover:shadow-xl hover:scale-[1.02] active:scale-95 transition-all"
            >
              <BookOpen className="w-4 h-4" />
              Browse catalog
            </Link>
            <Link
              to="/student/enrollments"
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-white/10 backdrop-blur-sm text-white font-semibold text-sm border border-white/20 hover:bg-white/20 transition-all"
            >
              My enrollments
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Active courses"
          value={activeEnrollments.length}
          hint="In progress"
          icon={BookOpen}
          accent="brand"
        />
        <StatCard
          label="Certificates"
          value={certCount}
          hint="Earned credentials"
          icon={Award}
          accent="emerald"
        />
        <StatCard
          label="Avg progress"
          value={formatPercent(avgCompletion)}
          hint="Across active courses"
          icon={TrendingUp}
          accent="violet"
        />
        <StatCard
          label="Total enrollments"
          value={totalEnrollments}
          hint="Lifetime"
          icon={Clock}
          accent="amber"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-white rounded-2xl border border-border overflow-hidden">
          <div className="flex items-center justify-between px-5 py-4 border-b border-border">
            <div>
              <h2 className="font-semibold text-neutral-800">Active enrollments</h2>
              <p className="text-xs text-neutral-500 mt-0.5">Pick up where you left off</p>
            </div>
            <Link
              to="/student/enrollments"
              className="inline-flex items-center gap-1 text-sm font-medium text-brand-600 hover:text-brand-700"
            >
              View all
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          {loadingEnrollments ? (
            <LoadingSpinner className="py-12" />
          ) : activeEnrollments.length === 0 ? (
            <div className="py-12 px-6 text-center">
              <div className="w-14 h-14 mx-auto rounded-full bg-brand-50 flex items-center justify-center mb-3">
                <BookOpen className="w-6 h-6 text-brand-600" />
              </div>
              <p className="text-sm font-medium text-neutral-700">No active courses yet</p>
              <p className="text-xs text-neutral-500 mt-1">
                Find a course that sparks your curiosity.
              </p>
              <Link
                to="/student/catalog"
                className="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-brand-600 hover:text-brand-700"
              >
                Browse catalog
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          ) : (
            <ul className="divide-y divide-border">
              {activeEnrollments.map((e) => (
                <EnrollmentRow key={e.id} enrollment={e} />
              ))}
            </ul>
          )}
        </div>

        <div className="bg-white rounded-2xl border border-border overflow-hidden">
          <div className="flex items-center justify-between px-5 py-4 border-b border-border">
            <div>
              <h2 className="font-semibold text-neutral-800">Recent certificates</h2>
              <p className="text-xs text-neutral-500 mt-0.5">Your wins</p>
            </div>
            <Link
              to="/student/certificates"
              className="text-sm font-medium text-brand-600 hover:text-brand-700"
            >
              All
            </Link>
          </div>

          {loadingCerts ? (
            <LoadingSpinner className="py-8" />
          ) : certCount === 0 ? (
            <div className="py-10 px-5 text-center">
              <div className="w-12 h-12 mx-auto rounded-full bg-emerald-50 flex items-center justify-center mb-2">
                <Award className="w-5 h-5 text-emerald-600" />
              </div>
              <p className="text-xs text-neutral-500">
                Complete a course to earn your first certificate.
              </p>
            </div>
          ) : (
            <ul className="divide-y divide-border">
              {(certificates ?? []).slice(0, RECENT_CERT_LIMIT).map((cert) => (
                <li key={cert.id} className="px-5 py-3.5">
                  <div className="flex items-start gap-3">
                    <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-emerald-400 to-emerald-600 flex items-center justify-center shrink-0 shadow-sm">
                      <Award className="w-4 h-4 text-white" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-neutral-800 truncate">
                        {cert.course_name}
                      </p>
                      <p className="text-[11px] text-neutral-500 font-mono truncate">
                        {cert.cert_number}
                      </p>
                      <p className="text-[11px] text-neutral-400 mt-0.5">
                        {formatDate(cert.issued_at)}
                      </p>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  )
}
