import { Award, Download, ExternalLink, ShieldCheck } from 'lucide-react'
import { useAuth } from '@/lib/auth/useAuth'
import { useCertificates } from '@/lib/api/credentialing'
import { formatDate } from '@/lib/utils/format'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'

export default function Certificates() {
  const { user } = useAuth()
  const { data: certificates, isLoading, isError } = useCertificates(user?.id)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">My Certificates</h1>
        <p className="text-sm text-neutral-500 mt-0.5">Your earned credentials</p>
      </div>

      {isLoading && <LoadingSpinner className="py-20" size="lg" />}

      {isError && (
        <EmptyState
          title="Failed to load certificates"
          description="Could not fetch your certificates. Please try again."
        />
      )}

      {!isLoading && !isError && (certificates?.length ?? 0) === 0 && (
        <EmptyState
          title="No certificates yet"
          description="Complete a course to earn your first certificate."
        />
      )}

      {!isLoading && !isError && (certificates?.length ?? 0) > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {(certificates ?? []).map((cert) => (
            <div
              key={cert.id}
              className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] hover:shadow-md transition-shadow overflow-hidden"
            >
              {/* Card header */}
              <div className="bg-gradient-to-br from-emerald-500 to-emerald-600 px-5 py-4 flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                  <Award className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-white text-sm truncate">{cert.course_name}</p>
                  <p className="text-emerald-100 text-[11px] font-mono truncate mt-0.5">
                    {cert.cert_number}
                  </p>
                </div>
                {cert.status === 'valid' && (
                  <ShieldCheck className="w-5 h-5 text-emerald-200 shrink-0" />
                )}
              </div>

              {/* Card body */}
              <div className="px-5 py-4 space-y-3">
                <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-neutral-500">
                  <span>Issued: <span className="text-neutral-700 font-medium">{formatDate(cert.issued_at)}</span></span>
                  {cert.expires_at && (
                    <span>Expires: <span className="text-neutral-700 font-medium">{formatDate(cert.expires_at)}</span></span>
                  )}
                </div>

                <div className="flex items-center gap-2 pt-1">
                  <a
                    href={`/verify/${cert.cert_number}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-neutral-600 border border-neutral-200 rounded-lg hover:bg-neutral-50 transition-colors"
                  >
                    <ExternalLink className="w-3.5 h-3.5" />
                    Verify
                  </a>
                  <button className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-white bg-emerald-600 rounded-lg hover:bg-emerald-700 transition-colors">
                    <Download className="w-3.5 h-3.5" />
                    Download
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
