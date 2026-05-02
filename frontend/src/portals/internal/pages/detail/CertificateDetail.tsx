import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Award, Ban } from 'lucide-react'
import { toast } from 'sonner'
import DetailPageLayout, { type DetailTab, type BreadcrumbItem } from '@/components/layout/DetailPageLayout'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import Button from '@/components/ui/Button'
import Textarea from '@/components/ui/Textarea'
import RoleGate from '@/components/shared/RoleGate'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { useCertificate, useRevokeCertificate } from '@/lib/api/certificate-issue'

const TABS: DetailTab[] = [{ value: 'overview', label: 'Overview' }]
const REVOKED = 'revoked'
const MIN_REASON = 3

const STATUS_BADGE: Record<string, string> = {
  issued: 'bg-emerald-50 text-emerald-700',
  revoked: 'bg-red-50 text-red-700',
}

export default function CertificateDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data, isLoading } = useCertificate(id)
  const revoke = useRevokeCertificate(id)

  const [reasonOpen, setReasonOpen] = useState(false)
  const [reason, setReason] = useState('')
  const [confirmOpen, setConfirmOpen] = useState(false)

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Academic', to: '/internal/academic' },
    { label: 'Certificates', to: '/internal/certificates' },
    { label: data.code || data.id },
  ]

  const isRevoked = data.status === REVOKED

  function openReason() {
    setReason('')
    setReasonOpen(true)
  }

  function proceedToConfirm() {
    if (reason.trim().length < MIN_REASON) {
      toast.error('Reason minimal 3 karakter')
      return
    }
    setReasonOpen(false)
    setConfirmOpen(true)
  }

  async function doRevoke() {
    try {
      await revoke.mutateAsync({ reason: reason.trim() })
      toast.success('Revoke request submitted (pending approval)')
      setConfirmOpen(false)
      navigate('/internal/certificates')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to revoke certificate')
    }
  }

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<Award className="w-5 h-5 text-brand-600" />}
      title={data.code || 'Certificate'}
      subtitle={data.student_name || data.student_id}
      actions={
        !isRevoked && (
          <RoleGate action="approve" resource="certificate">
            <Button variant="secondary" onClick={openReason}>
              <Ban className="w-4 h-4" /> Revoke
            </Button>
          </RoleGate>
        )
      }
      tabs={TABS}
      activeTab="overview"
      onTabChange={() => {}}
    >
      <div className="space-y-6 max-w-3xl">
        <section className="grid grid-cols-2 gap-4">
          <Field label="Code" value={data.code || '—'} mono />
          <Field
            label="Status"
            value={
              <span className={`capitalize px-2 py-0.5 rounded-md text-xs ${STATUS_BADGE[data.status] ?? 'bg-neutral-100'}`}>
                {data.status}
              </span>
            }
          />
          <Field label="Type" value={<span className="capitalize">{data.type}</span>} />
          <Field label="Issued At" value={data.issued_at ? new Date(data.issued_at).toLocaleString() : '—'} />
          <Field label="Student" value={data.student_name || data.student_id} />
          <Field label="Batch" value={data.batch_name || data.batch_id} />
          <Field label="Course" value={data.course_id} />
          <Field label="Template" value={data.template_id} />
        </section>

        {data.verification_url && (
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Verification URL</h3>
            <a
              href={data.verification_url}
              target="_blank"
              rel="noreferrer"
              className="text-sm text-brand-600 underline break-all"
            >
              {data.verification_url}
            </a>
          </section>
        )}

        {isRevoked && (
          <section className="bg-red-50 border border-red-100 rounded-lg p-4">
            <h3 className="text-xs font-semibold text-red-700 uppercase mb-1">Revoked</h3>
            <p className="text-sm text-red-700">
              {data.revoked_at ? new Date(data.revoked_at).toLocaleString() : '—'}
            </p>
            <p className="text-sm text-red-700 mt-1">{data.revoke_reason || '—'}</p>
          </section>
        )}
      </div>

      {/* Reason dialog (native textarea, no extra deps) */}
      {reasonOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md bg-white rounded-xl shadow-xl p-6">
            <h2 className="text-base font-semibold text-neutral-900">Revoke Certificate</h2>
            <p className="text-sm text-neutral-500 mt-1">
              Multi-step approval will be initiated (Dept Leader → Education Leader → Director).
            </p>
            <Textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              rows={4}
              placeholder="Reason for revocation"
              className="mt-3"
            />
            <div className="mt-6 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setReasonOpen(false)}
                className="px-4 py-2 text-sm font-medium text-neutral-700 bg-neutral-100 rounded-lg hover:bg-neutral-200"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={proceedToConfirm}
                className="px-4 py-2 text-sm font-medium text-white rounded-lg bg-red-600 hover:bg-red-700"
              >
                Continue
              </button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={confirmOpen}
        onCancel={() => setConfirmOpen(false)}
        onConfirm={doRevoke}
        title="Confirm revocation"
        description={`Are you sure you want to revoke this certificate? Reason: "${reason.trim()}"`}
        confirmLabel="Revoke"
        destructive
      />
    </DetailPageLayout>
  )
}

function Field({ label, value, mono }: { label: string; value: React.ReactNode; mono?: boolean }) {
  return (
    <div>
      <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">{label}</h3>
      <div className={`text-sm text-neutral-700 break-words ${mono ? 'font-mono' : ''}`}>{value}</div>
    </div>
  )
}
