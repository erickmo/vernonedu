import { toast } from 'sonner'
import Button from '@/components/ui/Button'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import RoleGate from '@/components/shared/RoleGate'
import { useCourseVersion, usePromoteCourseVersion } from '@/lib/api/curriculum'
import { useAuth } from '@/lib/auth/useAuth'

interface Props {
  versionId: string
  typeId: string
}

function fmtDateTime(s?: string | null) {
  if (!s) return '—'
  return new Date(s).toLocaleString('id-ID')
}

export default function VersionDetailPanel({ versionId, typeId }: Props) {
  const { data: version, isLoading } = useCourseVersion(versionId)
  const promote = usePromoteCourseVersion(typeId)
  const { user } = useAuth()

  if (isLoading || !version) return <LoadingSpinner size="lg" />

  async function doPromote(target: 'review' | 'approved') {
    const msg = target === 'review'
      ? 'Submit for review? Reviewer will be notified.'
      : 'Approve this version? This will archive any currently approved version.'
    if (!confirm(msg)) return
    try {
      await promote.mutateAsync({
        versionId,
        input: target === 'approved'
          ? { target_status: 'approved', approved_by: user?.id }
          : { target_status: 'review' },
      })
      toast.success(target === 'review' ? 'Submitted for review' : 'Version approved')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to promote version')
    }
  }

  const v = version

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-lg text-neutral-900">v{v.version_number}</h3>
        <div className="flex gap-2">
          {v.status === 'draft' && (
            <RoleGate action="update" resource="courseversion">
              <Button size="sm" variant="secondary" onClick={() => doPromote('review')}>
                Submit for review
              </Button>
            </RoleGate>
          )}
          {v.status === 'review' && (
            <RoleGate action="approve" resource="courseversion">
              <Button size="sm" onClick={() => doPromote('approved')}>
                Approve
              </Button>
            </RoleGate>
          )}
        </div>
      </div>

      <dl className="grid grid-cols-2 gap-3 text-sm">
        <div>
          <dt className="text-neutral-500">Status</dt>
          <dd className="text-neutral-900 capitalize">{v.status}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Change Type</dt>
          <dd className="text-neutral-900 capitalize">{v.change_type}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Created</dt>
          <dd className="text-neutral-900">{fmtDateTime(v.created_at)}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Approved at</dt>
          <dd className="text-neutral-900">{fmtDateTime(v.approved_at)}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Approved by</dt>
          <dd className="text-neutral-900 truncate">{v.approved_by ?? '—'}</dd>
        </div>
        <div>
          <dt className="text-neutral-500">Archived at</dt>
          <dd className="text-neutral-900">{fmtDateTime(v.archived_at)}</dd>
        </div>
      </dl>

      <div>
        <div className="text-xs uppercase tracking-wide text-neutral-500 mb-1">Changelog</div>
        <pre className="whitespace-pre-wrap text-sm text-neutral-800 bg-neutral-50 p-3 rounded-lg border border-neutral-100">
{v.changelog}
        </pre>
      </div>
    </div>
  )
}
