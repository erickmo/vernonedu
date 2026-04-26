import { BookOpen, Award, Clock, AlertCircle } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { useEnrollments } from '@/lib/api/enrollment'
import { useCertificates } from '@/lib/api/credentialing'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

export default function StudentDashboard() {
  const { user } = useAuth()
  const { data: enrollmentsData, isLoading: loadingEnrollments } = useEnrollments({
    student_id: user?.id,
    status: 'confirmed',
    limit: 5,
  })
  const { data: certificates, isLoading: loadingCerts } = useCertificates(user?.id)

  const activeEnrollments = enrollmentsData?.data ?? []
  const profileComplete = user?.name && user?.email

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">
          Welcome back, {user?.name?.split(' ')[0]} 👋
        </h1>
        <p className="text-neutral-500 mt-1">Here's what's happening with your learning journey.</p>
      </div>

      {!profileComplete && (
        <div className="flex items-start gap-3 p-4 bg-amber-50 border border-amber-200 rounded-lg">
          <AlertCircle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div className="flex-1">
            <p className="text-sm font-medium text-amber-800">Complete your profile</p>
            <p className="text-xs text-amber-700 mt-0.5">
              Add your details to unlock all features.
            </p>
          </div>
          <Link
            to="/student/profile"
            className="text-xs font-medium text-amber-700 hover:text-amber-900 underline"
          >
            Complete now
          </Link>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl border border-border p-5">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-brand-100 flex items-center justify-center">
              <BookOpen className="w-5 h-5 text-brand-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-neutral-900">{activeEnrollments.length}</p>
              <p className="text-sm text-neutral-500">Active courses</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-border p-5">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-emerald-100 flex items-center justify-center">
              <Award className="w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-neutral-900">{certificates?.length ?? 0}</p>
              <p className="text-sm text-neutral-500">Certificates earned</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-border p-5">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-violet-100 flex items-center justify-center">
              <Clock className="w-5 h-5 text-violet-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-neutral-900">
                {enrollmentsData?.total ?? 0}
              </p>
              <p className="text-sm text-neutral-500">Total enrollments</p>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-border">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <h2 className="font-semibold text-neutral-800">Active Enrollments</h2>
          <Link to="/student/enrollments" className="text-sm text-brand-600 hover:text-brand-700">
            View all
          </Link>
        </div>

        {loadingEnrollments ? (
          <LoadingSpinner className="py-12" />
        ) : activeEnrollments.length === 0 ? (
          <div className="py-12 text-center">
            <p className="text-neutral-500 text-sm">No active enrollments.</p>
            <Link to="/student/catalog" className="text-sm text-brand-600 hover:text-brand-700 mt-2 inline-block">
              Browse courses
            </Link>
          </div>
        ) : (
          <ul className="divide-y divide-border">
            {activeEnrollments.map((e) => (
              <li key={e.id} className="flex items-center justify-between px-5 py-4">
                <div>
                  <p className="text-sm font-medium text-neutral-800">{e.batch_id}</p>
                  <p className="text-xs text-neutral-500 mt-0.5">
                    Enrolled {formatDate(e.enrolled_at)}
                  </p>
                </div>
                <div className="flex items-center gap-3">
                  <div className="text-right">
                    <p className="text-xs text-neutral-500 mb-1">Completion</p>
                    <div className="w-24 h-1.5 bg-neutral-100 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-brand-500 rounded-full"
                        style={{ width: `${e.completion_percent}%` }}
                      />
                    </div>
                  </div>
                  <StatusBadge status={e.payment_status} variant="payment" />
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="bg-white rounded-xl border border-border">
        <div className="flex items-center justify-between px-5 py-4 border-b border-border">
          <h2 className="font-semibold text-neutral-800">Recent Certificates</h2>
          <Link to="/student/certificates" className="text-sm text-brand-600 hover:text-brand-700">
            View all
          </Link>
        </div>

        {loadingCerts ? (
          <LoadingSpinner className="py-8" />
        ) : (certificates?.length ?? 0) === 0 ? (
          <p className="py-8 text-center text-sm text-neutral-500">No certificates yet.</p>
        ) : (
          <ul className="divide-y divide-border">
            {(certificates ?? []).slice(0, 3).map((cert) => (
              <li key={cert.id} className="flex items-center justify-between px-5 py-4">
                <div>
                  <p className="text-sm font-medium text-neutral-800">{cert.course_name}</p>
                  <p className="text-xs text-neutral-500 mt-0.5">{cert.cert_number}</p>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-xs text-neutral-500">{formatDate(cert.issued_at)}</span>
                  <StatusBadge status={cert.status} />
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
