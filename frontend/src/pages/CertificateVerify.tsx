import { useParams } from 'react-router-dom'
import { Award, CheckCircle, XCircle, AlertCircle, GraduationCap } from 'lucide-react'
import { useVerifyCertificate } from '@/lib/api/credentialing'
import { formatDate } from '@/lib/utils/format'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

export default function CertificateVerify() {
  const { certNumber } = useParams<{ certNumber: string }>()
  const { data, isLoading, isError } = useVerifyCertificate(certNumber ?? '')

  return (
    <div className="min-h-screen bg-gradient-to-br from-brand-50 to-neutral-100 flex flex-col">
      <header className="bg-white border-b border-border px-6 py-4">
        <div className="max-w-xl mx-auto flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-brand-600 flex items-center justify-center">
            <GraduationCap className="w-5 h-5 text-white" />
          </div>
          <span className="font-bold text-neutral-900">VernonEdu</span>
          <span className="text-neutral-300">|</span>
          <span className="text-sm text-neutral-500">Certificate Verification</span>
        </div>
      </header>

      <main className="flex-1 flex items-center justify-center p-4">
        <div className="w-full max-w-xl">
          {isLoading && (
            <div className="bg-white rounded-2xl border border-border shadow-sm p-12 text-center">
              <LoadingSpinner size="lg" className="mb-4" />
              <p className="text-sm text-neutral-500">Verifying certificate...</p>
            </div>
          )}

          {isError && (
            <div className="bg-white rounded-2xl border border-border shadow-sm p-8 text-center">
              <div className="w-16 h-16 rounded-full bg-red-100 flex items-center justify-center mx-auto mb-4">
                <AlertCircle className="w-8 h-8 text-red-600" />
              </div>
              <h2 className="text-lg font-semibold text-neutral-800">Verification Failed</h2>
              <p className="text-sm text-neutral-500 mt-2">
                Could not verify certificate <span className="font-mono font-medium">{certNumber}</span>. Please try again.
              </p>
            </div>
          )}

          {!isLoading && !isError && data && (
            <div className="bg-white rounded-2xl border border-border shadow-sm overflow-hidden">
              <div
                className={`h-3 ${
                  data.valid && data.certificate?.status === 'valid'
                    ? 'bg-gradient-to-r from-emerald-400 to-emerald-600'
                    : 'bg-gradient-to-r from-red-400 to-red-600'
                }`}
              />

              <div className="p-8">
                <div className="flex items-start gap-5">
                  <div
                    className={`w-16 h-16 rounded-2xl flex items-center justify-center shrink-0 ${
                      data.valid && data.certificate?.status === 'valid'
                        ? 'bg-emerald-100'
                        : 'bg-red-100'
                    }`}
                  >
                    {data.valid && data.certificate?.status === 'valid' ? (
                      <CheckCircle className="w-8 h-8 text-emerald-600" />
                    ) : (
                      <XCircle className="w-8 h-8 text-red-600" />
                    )}
                  </div>

                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <h2 className="text-xl font-bold text-neutral-900">
                        {data.valid && data.certificate?.status === 'valid'
                          ? 'Valid Certificate'
                          : 'Invalid Certificate'}
                      </h2>
                      {data.certificate?.status === 'revoked' && (
                        <span className="px-2 py-0.5 text-xs font-medium bg-red-100 text-red-700 rounded-full">
                          Revoked
                        </span>
                      )}
                      {data.certificate?.status === 'expired' && (
                        <span className="px-2 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">
                          Expired
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-neutral-500 mt-0.5">{data.message}</p>
                  </div>
                </div>

                {data.certificate && (
                  <div className="mt-6 space-y-4">
                    <div className="rounded-xl bg-neutral-50 border border-border p-5 space-y-3">
                      <div className="flex items-center gap-2 mb-4">
                        <Award className="w-4 h-4 text-brand-600" />
                        <span className="text-sm font-semibold text-neutral-700">Certificate Details</span>
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <p className="text-xs text-neutral-400 uppercase tracking-wide mb-0.5">Certificate No.</p>
                          <p className="text-sm font-mono font-medium text-neutral-800">
                            {data.certificate.cert_number}
                          </p>
                        </div>
                        <div>
                          <p className="text-xs text-neutral-400 uppercase tracking-wide mb-0.5">Student</p>
                          <p className="text-sm font-medium text-neutral-800">{data.certificate.student_name}</p>
                        </div>
                        <div className="col-span-2">
                          <p className="text-xs text-neutral-400 uppercase tracking-wide mb-0.5">Course</p>
                          <p className="text-sm font-medium text-neutral-800">{data.certificate.course_name}</p>
                        </div>
                        <div>
                          <p className="text-xs text-neutral-400 uppercase tracking-wide mb-0.5">Issue Date</p>
                          <p className="text-sm text-neutral-700">{formatDate(data.certificate.issued_at)}</p>
                        </div>
                        {data.certificate.expires_at && (
                          <div>
                            <p className="text-xs text-neutral-400 uppercase tracking-wide mb-0.5">Expiry Date</p>
                            <p className="text-sm text-neutral-700">{formatDate(data.certificate.expires_at)}</p>
                          </div>
                        )}
                      </div>
                    </div>

                    {data.certificate.status === 'revoked' && data.certificate.revoke_reason && (
                      <div className="rounded-xl bg-red-50 border border-red-200 p-4">
                        <p className="text-xs font-medium text-red-700 mb-1">Revocation Reason</p>
                        <p className="text-sm text-red-600">{data.certificate.revoke_reason}</p>
                        {data.certificate.revoked_at && (
                          <p className="text-xs text-red-500 mt-1">
                            Revoked on {formatDate(data.certificate.revoked_at)}
                          </p>
                        )}
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          )}

          <p className="text-center text-xs text-neutral-400 mt-4">
            Verified by VernonEdu · {new Date().getFullYear()}
          </p>
        </div>
      </main>
    </div>
  )
}
