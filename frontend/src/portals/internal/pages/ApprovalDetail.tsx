import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { CheckCircle2, ShieldCheck, XCircle, Ban } from 'lucide-react'
import DetailPageLayout, { type BreadcrumbItem, type DetailTab } from '@/components/layout/DetailPageLayout'

const TABS: DetailTab[] = [{ value: 'overview', label: 'Overview' }]
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'
import Button from '@/components/ui/Button'
import RoleGate from '@/components/shared/RoleGate'
import { useApproval } from '@/lib/api/approval'
import { useAuth } from '@/lib/auth/useAuth'
import ApprovalWizard, { type WizardMode } from '../components/approvals/ApprovalWizard'

export default function ApprovalDetail() {
  const { id = '' } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { user } = useAuth()
  const { data, isLoading } = useApproval(id)

  const [wizardMode, setWizardMode] = useState<WizardMode | null>(null)

  if (isLoading || !data) return <LoadingSpinner size="lg" />

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Operations', to: '/internal/operations' },
    { label: 'Approvals', to: '/internal/approvals' },
    { label: data.title },
  ]

  const isPending = data.status === 'pending'
  const isApprover = !!user?.id && user.id === data.approver_id
  const isRequester = !!user?.id && user.id === data.requested_by_id

  return (
    <DetailPageLayout
      breadcrumbs={breadcrumbs}
      icon={<ShieldCheck className="w-5 h-5 text-brand-600" />}
      title={data.title}
      subtitle={data.type.replace(/_/g, ' ')}
      status={<StatusBadge status={data.status} />}
      actions={
        <div className="flex gap-2">
          {isPending && isApprover && (
            <>
              <RoleGate action="approve" resource="approval">
                <Button variant="primary" onClick={() => setWizardMode('approve')}>
                  <CheckCircle2 className="w-4 h-4" /> Approve
                </Button>
              </RoleGate>
              <RoleGate action="approve" resource="approval">
                <Button variant="danger" onClick={() => setWizardMode('reject')}>
                  <XCircle className="w-4 h-4" /> Reject
                </Button>
              </RoleGate>
            </>
          )}
          {isPending && isRequester && (
            <Button variant="secondary" onClick={() => setWizardMode('cancel')}>
              <Ban className="w-4 h-4" /> Cancel
            </Button>
          )}
        </div>
      }
      tabs={TABS}
      activeTab="overview"
      onTabChange={() => {}}
    >
      <div className="space-y-6 max-w-3xl">
        <section>
          <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Description</h3>
          <p className="text-sm text-neutral-700 whitespace-pre-wrap">{data.description || '—'}</p>
        </section>
        <div className="grid grid-cols-2 gap-6">
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Requested By</h3>
            <p className="text-sm text-neutral-700">{data.requested_by_name ?? data.requested_by_id}</p>
          </section>
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Approver</h3>
            <p className="text-sm text-neutral-700">{data.approver_name ?? data.approver_id}</p>
          </section>
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Entity</h3>
            <p className="text-sm text-neutral-700">
              {data.entity_type ? `${data.entity_type} · ${data.entity_id}` : '—'}
            </p>
          </section>
          <section>
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Decided At</h3>
            <p className="text-sm text-neutral-700">
              {data.decided_at ? new Date(data.decided_at).toLocaleString() : '—'}
            </p>
          </section>
        </div>
        {data.reason && (
          <section className="pt-4 border-t border-neutral-100">
            <h3 className="text-xs font-semibold text-neutral-500 uppercase mb-1">Decision Reason</h3>
            <p className="text-sm text-neutral-700 whitespace-pre-wrap">{data.reason}</p>
          </section>
        )}
        <section className="pt-4 border-t border-neutral-100 text-xs text-neutral-500">
          Created: {new Date(data.created_at).toLocaleString()}
        </section>
      </div>

      {wizardMode && (
        <ApprovalWizard
          approval={data}
          mode={wizardMode}
          open
          onClose={() => setWizardMode(null)}
        />
      )}

      <button
        type="button"
        onClick={() => navigate('/internal/approvals')}
        className="hidden"
        aria-hidden
      />
    </DetailPageLayout>
  )
}
