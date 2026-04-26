import { Award, Download, ExternalLink } from 'lucide-react'
import { useAuth } from '@/lib/auth/useAuth'
import { useCertificates } from '@/lib/api/credentialing'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import EmptyState from '@/components/shared/EmptyState'
import PageHeader from '@/components/shared/PageHeader'

export default function Certificates() {
  const { user } = useAuth()
  const { data: certificates, isLoading, isError } = useCertificates(user?.id)

  return (
    <div className="space-y-6">
      <PageHeader
        title="My Certificates"
        subtitle="Your earned certifications"
        breadcrumbs={[{ label: 'Certificates' }]}
      />

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
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {(certificates ?? []).map((cert) => (
            <div
              key={cert.id}
              className="bg-white rounded-xl border border-border p-5 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-brand-100 flex items-center justify-center shrink-0">
                  <Award className="w-6 h-6 text-brand-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="font-semibold text-neutral-900 text-sm truncate">
                      {cert.course_name}
                    </h3>
                    <StatusBadge status={cert.status} />
                  </div>
                  <p className="text-xs text-neutral-500 mt-1 font-mono">{cert.cert_number}</p>
                  <div className="flex items-center gap-4 mt-2 text-xs text-neutral-500">
                    <span>Issued: {formatDate(cert.issued_at)}</span>
                    {cert.expires_at && (
                      <span>Expires: {formatDate(cert.expires_at)}</span>
                    )}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2 mt-4 pt-4 border-t border-border">
                <a
                  href={`/verify/${cert.cert_number}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-neutral-600 border border-border rounded-lg hover:bg-neutral-50 transition-colors"
                >
                  <ExternalLink className="w-3.5 h-3.5" />
                  Verify
                </a>
                <button className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors">
                  <Download className="w-3.5 h-3.5" />
                  Download
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
